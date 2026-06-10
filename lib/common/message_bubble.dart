import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final List<dynamic> selectedMessages;
  final Function(String id) onSelect;
  final Function(String id) onUnselect;

  const MessageBubble({
    super.key,
    required this.data,
    required this.isMe,
    required this.selectedMessages,
    required this.onSelect,
    required this.onUnselect,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    Timestamp? timeStamp = widget.data['timestamp'];
    DateTime? time = timeStamp?.toDate();

    String formattedTime = "";
    if (time != null) {
      formattedTime = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }

    return Obx(() {
      final messageId = widget.data["messageId"];
      final isSelected = widget.selectedMessages.contains(messageId);
      return Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () {
            if (!widget.isMe) return;
            if (isSelected) {
              widget.onUnselect(messageId);
            } else {
              widget.onSelect(messageId);
            }
          },
          onTap: () {
            if (widget.selectedMessages.isNotEmpty) {
              if (isSelected) {
                widget.onUnselect(messageId);
              } else {
                widget.onSelect(messageId);
              }
            }
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withValues(alpha: 0.25)
                  : (widget.isMe ? const Color(0xFFDCF8C6) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                bottomRight: Radius.circular(widget.isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if ((widget.data['type'] ?? '') == 'image')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.data['message'] ?? "",
                      height: 180,
                      width: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 60);
                      },
                    ),
                  ),

                if ((widget.data['type'] ?? '') == 'video')
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_fill, size: 60),
                    ),
                  ),

                if (widget.data['type'] == 'text')
                  Text(
                    widget.data['message'] ?? "",
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),

                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (widget.isMe)
                      Icon(
                        widget.data['isSeen'] == true
                            ? Icons.done_all
                            : Icons.check,
                        size: 16,
                        color: widget.data['isSeen'] == true
                            ? Colors.blue
                            : Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
