import 'package:flutter/material.dart';
import 'package:roeyp/core/theme/app_colors.dart';

class PinNumpad extends StatelessWidget {
  final Function(String) onNumberTap;
  final VoidCallback onBackspace;
  final bool enabled;

  const PinNumpad({
    super.key,
    required this.onNumberTap,
    required this.onBackspace,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240), // More compact width
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16, // Slightly tighter vertical spacing
            crossAxisSpacing: 24, // Horizontal spacing
            childAspectRatio: 1,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            if (index == 9) return const SizedBox.shrink(); // Empty bottom-left
            if (index == 11) {
              return _buildKey(
                child: const Icon(Icons.backspace_outlined, color: AppColors.error),
                onTap: onBackspace,
              );
            }
            
            final number = index == 10 ? '0' : '${index + 1}';
            final letters = _getLetters(number);
            
            return _buildKey(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 28, 
                      height: 1.1,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (letters.isNotEmpty)
                    Text(
                      letters,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withOpacity(0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                ],
              ),
              onTap: () => onNumberTap(number),
            );
          },
        ),
      ),
    );
  }

  String _getLetters(String number) {
    switch (number) {
      case '2': return 'A B C';
      case '3': return 'D E F';
      case '4': return 'G H I';
      case '5': return 'J K L';
      case '6': return 'M N O';
      case '7': return 'P Q R S';
      case '8': return 'T U V';
      case '9': return 'W X Y Z';
      default: return '';
    }
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), // Subtle glass effect
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withOpacity(0.2)),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
