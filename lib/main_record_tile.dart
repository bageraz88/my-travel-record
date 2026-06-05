import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart' show TravelRecord;

class TravelRecordTile extends StatelessWidget {
  const TravelRecordTile({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenImage,
    required this.onShareImage,
    required this.formatDateTime,
  });

  final TravelRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenImage;
  final VoidCallback onShareImage;
  final String Function(DateTime) formatDateTime;

  Widget _buildImage(BuildContext context) {
    if (record.imageId == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: FutureBuilder<Uint8List?>(
        future: Future.value(Hive.box<Uint8List>('images').get(record.imageId)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            );
          }
          return Container(
            width: 72,
            height: 72,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported, size: 20),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String accessibilityLabel = 'Travel record for ${record.place.isEmpty ? 'Untitled place' : record.place}. '
        '${record.distanceType}: ${record.distanceValue}. '
        'Recorded on ${formatDateTime(record.time)}.';

    return Semantics(
      label: accessibilityLabel,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(context),
              if (record.imageId != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.place.isEmpty ? 'Untitled place' : record.place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.distanceType}: ${record.distanceValue}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDateTime(record.time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit record',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                tooltip: 'Delete record',
                onPressed: onDelete,
              ),
              if (record.imageId != null) ...[
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  tooltip: 'Share image',
                  onPressed: onShareImage,
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 20),
                  tooltip: 'Open image',
                  onPressed: onOpenImage,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
