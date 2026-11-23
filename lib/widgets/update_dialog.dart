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
        // 모양/배경은 테마(dialogTheme)를 따른다
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 340, // 최대 너비 고정
            minWidth: 300, // 최소 너비 고정
          ),
          child: Builder(builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘: 조용한 면 위의 선 아이콘
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerHighest,
                  ),
                  child: Icon(
                    isRequired ? Icons.system_update : Icons.update,
                    size: 28,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // 제목
                Text(
                  isRequired ? '업데이트 필수' : '업데이트 필요',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // 메시지
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // 버튼들 (주 버튼 = 버건디, 보조 = 헤어라인)
                if (isRequired)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _launchStore(context),
                      child: const Text('업데이트'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('나중에'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _launchStore(context);
                            },
                            child: const Text('업데이트'),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
          }),
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
