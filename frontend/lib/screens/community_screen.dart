import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  Map<String, dynamic>? _communityData;
  String? _error;
  List<Map<String, dynamic>> _messages = [];
  String? _roomId;
  String? _currentUsername;
  String? _currentUserId;
  String? _currentUserRole;
  
  List<dynamic> _availableClasses = [];
  String? _selectedGrade;
  String? _selectedSection;

  final List<String> _quickEmojis = ['😊', '👍', '❤️', '😂', '🎉', '📚', '✅', '❓', '👏', '🔥'];

  // Gamification & Tabs state
  int _currentTab = 0; // 0: Chat, 1: Challenges, 2: Leaderboard, 3: Members
  List<dynamic> _quests = [];
  List<dynamic> _leaderboard = [];
  bool _questsLoading = false;
  bool _leaderboardLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadCurrentUser();
    await _loadCommunity();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _apiService.getUserProfile();
      setState(() {
        _currentUsername = profile['username'];
        _currentUserId = profile['id'];
        _currentUserRole = profile['role'];
      });
    } catch (_) {}
  }

  Future<void> _loadCommunity({String? grade, String? section}) async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final data = await _apiService.getCommunity(
        grade: grade ?? _selectedGrade,
        section: section ?? _selectedSection,
      );
      
      final newRoomId = '${data['school']}_${data['grade']}_${data['section']}';
      
      setState(() {
        _communityData = data;
        _selectedGrade = data['grade'];
        _selectedSection = data['section'];
        _availableClasses = data['availableClasses'] ?? [];
        _roomId = newRoomId;
        _isLoading = false;
      });

      // Connect or update socket room
      _connectSocket();
      
      // Refresh current tab data
      if (_currentTab == 1) _loadQuests();
      if (_currentTab == 2) _loadLeaderboard();
    } catch (e) {
      setState(() { _error = 'فشل تحميل المجتمع'; _isLoading = false; });
    }
  }

  Future<void> _loadQuests() async {
    try {
      setState(() { _questsLoading = true; });
      final data = await _apiService.getQuests();
      setState(() {
        _quests = data;
        _questsLoading = false;
      });
    } catch (_) {
      setState(() { _questsLoading = false; });
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() { _leaderboardLoading = true; });
      final data = await _apiService.getLeaderboard();
      setState(() {
        _leaderboard = data;
        _leaderboardLoading = false;
      });
    } catch (_) {
      setState(() { _leaderboardLoading = false; });
    }
  }

  Future<void> _connectSocket() async {
    await _socketService.connect();
    if (_roomId != null) {
      _socketService.joinRoom(_roomId!);
    }
    _socketService.onRoomHistory((history) {
      if (mounted) {
        setState(() {
          _messages = history.map((m) => Map<String, dynamic>.from(m)).toList();
        });
        _scrollToBottom();
      }
    });
    _socketService.onMessage((message) {
      if (mounted) {
        setState(() => _messages.add(message));
        _scrollToBottom();
      }
    });
    _socketService.onMessageDeleted((messageId) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == messageId);
        });
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty || _roomId == null) return;
    _socketService.sendMessage(roomId: _roomId!, content: content.trim());
    _messageController.clear();
  }

  void _openUserProfile(String? userId) {
    if (userId == null || userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  Widget _buildAvatar({
    required String name,
    String? avatarUrl,
    required Color backgroundColor,
    double radius = 20,
    double fontSize = 14,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0] : '؟',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            )
          : null,
    );
  }

  void _showAnswersSheet(dynamic quest) async {
    List<dynamic> answers = [];
    bool loadingAnswers = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (loadingAnswers) {
              _apiService.getQuestAnswers(quest['id']).then((data) {
                setSheetState(() {
                  answers = data;
                  loadingAnswers = false;
                });
              });
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
            }

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إجابات الطلاب',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: answers.isEmpty
                        ? const Center(child: Text('لا توجد إجابات بعد', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: answers.length,
                            itemBuilder: (context, index) {
                              final ans = answers[index];
                              final user = ans['user'] ?? {};
                              final isCorrect = ans['isCorrect'] == true;
                              return Card(
                                color: Colors.black38,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: _buildAvatar(
                                    name: user['fullName'] ?? '؟',
                                    avatarUrl: user['avatarUrl'],
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                  title: Text(user['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(ans['content'] ?? '', style: const TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isCorrect ? Icons.check_circle : Icons.check_circle_outline,
                                      color: isCorrect ? Colors.green : Colors.grey,
                                    ),
                                    onPressed: isCorrect
                                        ? null
                                        : () async {
                                            final ok = await _apiService.validateQuestAnswer(quest['id'], ans['id']);
                                            if (ok) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('تم اختيار الإجابة الفائزة بنجاح! 🏆'), backgroundColor: Colors.green),
                                                );
                                                Navigator.pop(context);
                                                _loadQuests();
                                              }
                                            }
                                          },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      {'label': 'المحادثة', 'icon': Icons.chat_bubble_outline},
      {'label': 'التحديات', 'icon': Icons.emoji_events_outlined},
      {'label': 'المتصدرين', 'icon': Icons.leaderboard_outlined},
      {'label': 'الأعضاء', 'icon': Icons.people_outline},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.dividerColor.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _currentTab == index;
            final tab = tabs[index];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTab = index;
                  });
                  if (index == 1) {
                    _loadQuests();
                  } else if (index == 2) {
                    _loadLeaderboard();
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.sovereignGradient : null,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tab['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildQuestsTab() {
    if (_questsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_quests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_outlined, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'لا توجد تحديات نشطة حالياً 🏆',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                (_currentUserRole == 'TEACHER' || _currentUserRole == 'PRINCIPAL')
                    ? 'بإمكانك إضافة تحدٍ جديد للطلاب من زر النشر في القائمة السفلية!'
                    : 'ترقب التحديات والأسئلة من معلميك للحصول على النقاط والجوائز!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final isStudent = _currentUserRole == 'STUDENT';

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _quests.length,
      itemBuilder: (context, index) {
        final quest = _quests[index];
        final author = quest['author'] ?? {};
        final questId = quest['id'] as String;

        // Controller for fast answers
        final TextEditingController answerController = TextEditingController();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        quest['title'] ?? 'تحدي جديد',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Text(
                      '+${quest['points'] ?? 50} نقطة',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                quest['content'] ?? '',
                style: const TextStyle(color: Colors.white90, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildAvatar(
                        name: author['fullName'] ?? '؟',
                        avatarUrl: author['avatarUrl'],
                        backgroundColor: AppTheme.primaryColor,
                        radius: 12,
                        fontSize: 9,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'بواسطة المعلم: ${author['fullName'] ?? ''}',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  if (!isStudent)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      onPressed: () => _showAnswersSheet(quest),
                      icon: const Icon(Icons.visibility, size: 14),
                      label: const Text('عرض الإجابات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (isStudent) ...[
                const Divider(color: Colors.white24, height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: answerController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'اكتب إجابتك هنا بأسرع وقت...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.dividerColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () async {
                        final ans = answerController.text.trim();
                        if (ans.isEmpty) return;
                        final ok = await _apiService.submitQuestAnswer(questId, ans);
                        if (ok) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم تقديم إجابتك بنجاح! انتظر تصحيح المعلم ✅'), backgroundColor: Colors.green),
                            );
                            answerController.clear();
                            _loadQuests();
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('فشل تقديم الإجابة (قد تكون أجبت مسبقاً) ⚠️'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('إرسال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    if (_leaderboardLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Text('لا يوجد متصدرين بعد\nكن أول من يكسب نقاطاً! 🏆', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final student = _leaderboard[index];
        final rankNum = index + 1;
        
        Color cardColor = AppTheme.surfaceDark.withOpacity(0.5);
        BorderSide borderSide = BorderSide(color: AppTheme.dividerColor.withOpacity(0.3));
        Widget? trailingIcon;
        double avatarRadius = 20;

        if (rankNum == 1) {
          cardColor = Colors.amber.withOpacity(0.15);
          borderSide = const BorderSide(color: Colors.amber, width: 1.5);
          trailingIcon = const Icon(Icons.emoji_events, color: Colors.amber, size: 28);
          avatarRadius = 24;
        } else if (rankNum == 2) {
          cardColor = Colors.grey.withOpacity(0.15);
          borderSide = const BorderSide(color: Colors.grey, width: 1.2);
          trailingIcon = const Icon(Icons.emoji_events, color: Colors.grey, size: 24);
          avatarRadius = 22;
        } else if (rankNum == 3) {
          cardColor = Colors.brown.withOpacity(0.15);
          borderSide = const BorderSide(color: Colors.brown, width: 1.0);
          trailingIcon = const Icon(Icons.emoji_events, color: Colors.brown, size: 22);
          avatarRadius = 20;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(borderSide),
          ),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 25,
                  child: Text(
                    '#$rankNum',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: rankNum <= 3 ? 18 : 14,
                      color: rankNum == 1 ? Colors.amber : (rankNum == 2 ? Colors.grey : (rankNum == 3 ? Colors.brown : Colors.white70)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildAvatar(
                  name: student['fullName'] ?? '؟',
                  avatarUrl: student['avatarUrl'],
                  backgroundColor: rankNum == 1 ? Colors.amber : (rankNum == 2 ? Colors.grey.shade400 : (rankNum == 3 ? Colors.brown.shade400 : AppTheme.primaryColor)),
                  radius: avatarRadius,
                ),
              ],
            ),
            title: Text(
              student['fullName'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rankNum == 1 ? 16 : 14,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              '${student['rank'] ?? "طالب متميز"}',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${student['points'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16),
                    ),
                    const Text('نقطة', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  trailingIcon,
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: AppTheme.oledBlack, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    if (_error != null) return Scaffold(backgroundColor: AppTheme.oledBlack, body: Center(child: Text(_error!, style: TextStyle(color: AppTheme.textPrimary))));

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مجتمعي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            if (_communityData != null)
              Text(
                'الصف ${_selectedGrade ?? _communityData!['grade']} - شعبة ${_selectedSection ?? _communityData!['section']}',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
          ],
        ),
        bottom: (_availableClasses.length > 1) 
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _availableClasses.length,
                  itemBuilder: (context, index) {
                    final cls = _availableClasses[index];
                    final isSelected = cls['grade'] == _selectedGrade && cls['section'] == _selectedSection;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.groups_3_outlined, 
                          size: 16, 
                          color: isSelected ? Colors.black : AppTheme.primaryColor
                        ),
                        label: Text('مجموعة ${cls['grade']}-${cls['section']}'),
                        onPressed: () {
                          _loadCommunity(grade: cls['grade'], section: cls['section']);
                        },
                        backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.surfaceDark,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  },
                ),
              ),
            )
          : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () {
              if (_currentTab == 0) {
                _loadCommunity();
              } else if (_currentTab == 1) {
                _loadQuests();
              } else if (_currentTab == 2) {
                _loadLeaderboard();
              } else {
                _loadCommunity();
              }
            },
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16), // Rely on MainNavigation for most of the dock space
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: _currentTab == 0
                  ? _buildChat()
                  : (_currentTab == 1
                      ? _buildQuestsTab()
                      : (_currentTab == 2
                          ? _buildLeaderboardTab()
                          : _buildMembersList())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final students = _communityData?['students'] as List<dynamic>? ?? [];
    final teachers = _communityData?['teachers'] as List<dynamic>? ?? [];
    final allMembers = [
      ...teachers.map((t) => {...Map<String, dynamic>.from(t), 'isTeacher': true}),
      ...students.map((s) => {...Map<String, dynamic>.from(s), 'isTeacher': false}),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.surfaceDark,
          child: Row(
            children: [
              const Icon(Icons.people, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${allMembers.length} عضو',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 16),
              const Text(
                'معلم · طالب',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: allMembers.length,
            itemBuilder: (context, index) {
              final member = allMembers[index];
              final isTeacher = member['isTeacher'] == true;
              final avatarUrl = member['avatarUrl'] as String?;
              return ListTile(
                onTap: () => _openUserProfile(member['id']),
                leading: _buildAvatar(
                  name: member['fullName'] ?? '؟',
                  avatarUrl: avatarUrl,
                  backgroundColor: isTeacher ? Colors.teal : const Color(0xFF56877A),
                ),
                title: Text(
                  member['fullName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('@${member['username'] ?? ''}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTeacher
                        ? Colors.teal.withAlpha(30)
                        : const Color(0xFF56877A).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isTeacher ? 'معلم' : 'طالب',
                    style: TextStyle(
                      fontSize: 11,
                      color: isTeacher ? Colors.teal : const Color(0xFF56877A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'لا توجد رسائل بعد\nابدأ المحادثة! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return const SizedBox(height: 20); // Reduced since shell has 80
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
        ),

        // إيموجي سريعة
        Container(
          height: 48,
          color: AppTheme.surfaceDark,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: _quickEmojis.length,
            itemBuilder: (context, index) => InkWell(
              onTap: () => _sendMessage(_quickEmojis[index]),
              child: Container(
                width: 36,
                margin: const EdgeInsets.only(right: 4),
                alignment: Alignment.center,
                child: Text(_quickEmojis[index], style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ),

        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                      filled: true,
                      fillColor: AppTheme.oledBlack,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.oledBlack, size: 20),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['username'] == _currentUsername;
    final userId = message['userId'] as String?;
    final avatarUrl = message['avatarUrl'] as String?;
    final fullName = message['fullName'] as String? ?? '؟';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => _openUserProfile(userId),
              child: _buildAvatar(
                name: fullName,
                avatarUrl: avatarUrl,
                backgroundColor: AppTheme.surfaceDark,
                radius: 14,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
                border: isMe 
                    ? Border.all(color: AppTheme.primaryColor.withAlpha(100), width: 1)
                    : Border.all(color: AppTheme.dividerColor, width: 1),
                boxShadow: isMe ? AppTheme.primaryColorGlow : [],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    GestureDetector(
                      onTap: () => _openUserProfile(userId),
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  Text(
                    message['content'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['time'] ?? '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe || _currentUserRole == 'PRINCIPAL') 
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 18),
              onPressed: () {
                if (_roomId != null && message['id'] != null) {
                  _socketService.deleteMessage(_roomId!, message['id']);
                }
              },
            ),
        ],
      ),
    );
  }
}