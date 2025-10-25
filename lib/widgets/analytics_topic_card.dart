import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsTopicCard extends StatelessWidget {
  final TopicCluster topic;
  final VoidCallback onTap;

  const AnalyticsTopicCard({
    super.key,
    required this.topic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
      return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Topic emoji
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      topic.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Topic details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              topic.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'IBM Plex Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${topic.entries.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'IBM Plex Sans',
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 3),
                      
                      Text(
                        topic.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 13,
                          color: theme.brightness == Brightness.dark 
                            ? Colors.white.withOpacity(0.7) 
                            : Colors.black.withOpacity(0.6),
                        ),
                        maxLines: 2,                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Date range
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: theme.brightness == Brightness.dark 
                              ? Colors.white.withOpacity(0.5) 
                              : Colors.black.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateRange(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 11,
                              color: theme.brightness == Brightness.dark 
                                ? Colors.white.withOpacity(0.5) 
                                : Colors.black.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: theme.brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.4) 
                    : Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateRange() {
    final firstDate = topic.firstEntryDate;
    final lastDate = topic.lastEntryDate;
    
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    if (firstDate.year == lastDate.year) {
      if (firstDate.month == lastDate.month) {
        // Same month
        return '${monthNames[firstDate.month - 1]} ${firstDate.year}';
      } else {
        // Same year, different months
        return '${monthNames[firstDate.month - 1]} - ${monthNames[lastDate.month - 1]} ${firstDate.year}';
      }
    } else {
      // Different years
      return '${monthNames[firstDate.month - 1]} ${firstDate.year} - ${monthNames[lastDate.month - 1]} ${lastDate.year}';
    }
  }
}
