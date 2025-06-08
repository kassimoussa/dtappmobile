// lib/widgets/line_info_header.dart
import 'package:dtapp3/constants/app_theme.dart';
import 'package:flutter/material.dart';

class LineInfoHeader extends StatelessWidget {
  final String phoneNumber;
  
  const LineInfoHeader({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) { 
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.dtBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_android, size: 32, color: AppTheme.dtBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ligne active',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mobile prépayé',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.qr_code, color: AppTheme.dtBlue),
            onPressed: () {
              // Action pour afficher le QR code
            },
          ),
        ],
      ),
    );
  }
}