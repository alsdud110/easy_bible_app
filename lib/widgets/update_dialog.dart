import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_version_service.dart';
import '../utils/keep_words.dart';
import '../utils/responsive_utils.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 오늘의 구절 팝업과 같은 카드 톤(크림 면, 24 모서리, 부드러운 그림자, 버건디 포인트)
    return PopScope(
      canPop: !isRequired, // 강제 업데이트면 뒤로가기 불가
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.09),
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 30,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isRequired ? '업데이트 필수' : '업데이트 필요',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.titleFontSize(context),
                    color: cs.onSurface.withValues(alpha: 0.93),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  keepWords(message),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: ResponsiveUtils.bodyFontSize(context),
                    height: 1.6,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
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
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => UpdateDialog(
        updateType: updateType,
        message: message,
        storeUrl: versionService.storeUrl,
      ),
    );
  }
}
