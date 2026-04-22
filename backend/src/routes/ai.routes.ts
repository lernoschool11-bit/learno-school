import { Router } from 'express';
import { requireAuth, AuthRequest } from '../middleware/auth';
import prisma from '../lib/prisma';
import axios from 'axios';

const router = Router();

// OPENROUTER CONFIG
const OPENROUTER_API_KEY = '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';
const AI_MODEL = 'google/gemini-2.0-flash-lite-preview-02-05:free';
const DAILY_LIMIT = 20;

router.post('/chat', requireAuth, async (req: AuthRequest, res) => {
  try {
    const userId = req.user!.id;
    const { prompt, history } = req.body;

    if (!prompt) return res.status(400).json({ error: 'الرجاء إدخال نص' });

    // 1. Fetch user to check limits
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    // 2. Reset count if it's a new day
    const now = new Date();
    const lastRequest = user.lastAiRequest ? new Date(user.lastAiRequest) : null;
    
    let currentCount = user.aiRequestsCount;
    if (!lastRequest || lastRequest.toDateString() !== now.toDateString()) {
      currentCount = 0;
    }

    // 3. Check limit
    if (currentCount >= DAILY_LIMIT) {
      return res.status(429).json({ 
        error: `لقد وصلت للحد اليومي المسموح به (${DAILY_LIMIT} طلبات). حاول مرة أخرى غداً.` 
      });
    }

    // 4. Proxy to OpenRouter
    const messages = [
      { role: 'system', content: 'You are the Learno Assistant, a helpful AI for students in Jordan. Keep answers concise and educational.' },
      ...(history || []),
      { role: 'user', content: prompt }
    ];

    const response = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
      model: AI_MODEL,
      messages: messages,
      temperature: 0.7,
      max_tokens: 1024,
    }, {
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'HTTP-Referer': 'https://learno.app',
        'X-Title': 'Learno School',
        'Content-Type': 'application/json',
      }
    });

    const aiText = response.data.choices[0].message.content;

    // 5. Update user limits
    await prisma.user.update({
      where: { id: userId },
      data: {
        aiRequestsCount: currentCount + 1,
        lastAiRequest: now,
      }
    });

    res.json({ response: aiText });

  } catch (error: any) {
    console.error('AI Proxy Error:', error.response?.data || error.message);
    res.status(500).json({ error: 'حدث خطأ في الاتصال بخدمة الذكاء الاصطناعي' });
  }
});

export default router;
