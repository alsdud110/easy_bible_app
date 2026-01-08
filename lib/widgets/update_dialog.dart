import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_version_service.dart';

/// 업데이트 다이얼로그
class UpdateDialog extends StatelessWidget {
  final UpdateType updateType;
  final String message;
  final String storeUrl;

  const UpdateDialog({
    super.key,
    required this.updateType,
    required this.message,
    required this.storeUrl,
  });

  /// 앱 스토어로 이동
  Future<void> _launchStore(BuildContext context) async {
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('스토어를 열 수 없습니다.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRequired = updateType == UpdateType.required;

    return PopScope(
      canPop: !isRequired, // 강제 업데이트면 뒤로가기 불가
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 340, // 최대 너비 고정
            minWidth: 300, // 최소 너비 고정
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFB39DDB), // 밝은 보라
                        Color(0xFF9575CD), // 중간 보라
                        Color(0xFF7E57C2), // 진한 보라
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x669575CD),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRequired ? Icons.system_update : Icons.update,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // 제목
                Text(
                  isRequired ? '업데이트 필수' : '업데이트 필요',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 메시지
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 28),

                // 버튼들
                if (isRequired)
                  // 강제 업데이트: 업데이트 버튼만
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF8E6BC4), // 조금 더 진한 보라
                                Color(0xFF7550BA), // 조금 더 진한 보라
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D7550BA),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => _launchStore(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '업데이트',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // 선택적 업데이트: 취소 + 업데이트 버튼
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7E57C2),
                              side: const BorderSide(
                                color: Color(0xFF7E57C2),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '나중에',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF8E6BC4), // 조금 더 진한 보라
                                Color(0xFF7550BA), // 조금 더 진한 보라
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D7E57C2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _launchStore(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '업데이트',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 업데이트 다이얼로그 표시
  static Future<void> show(
    BuildContext context,
    AppVersionService versionService,
    UpdateType updateType,
  ) async {
    final message = updateType == UpdateType.required
        ? versionService.forceUpdateMessage
        : versionService.updateMessage;

    await showDialog(
      context: context,
      barrierDismissible: updateType != UpdateType.required,
      builder: (context) => UpdateDialog(
        updateType: updateType,
        message: message,
        storeUrl: versionService.storeUrl,
      ),
    );
  }
}
