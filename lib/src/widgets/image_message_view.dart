/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'dart:convert';
import 'dart:io';

import 'package:chatview_utils/chatview_utils.dart';
import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import '../models/config_models/image_message_configuration.dart';
import '../models/config_models/message_reaction_configuration.dart';
import 'reaction_widget.dart';
import 'share_icon.dart';

class ImageMessageView extends StatelessWidget {
  const ImageMessageView({
    Key? key,
    required this.message,
    required this.isMessageBySender,
    this.imageMessageConfig,
    this.messageReactionConfig,
    this.highlightImage = false,
    this.highlightScale = 1.2,
  }) : super(key: key);

  /// Provides message instance of chat.
  final Message message;

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Provides configuration for image message appearance.
  final ImageMessageConfiguration? imageMessageConfig;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents flag of highlighting image when user taps on replied image.
  final bool highlightImage;

  /// Provides scale of highlighted image when user taps on replied image.
  final double highlightScale;

  String get imageUrl => message.message;

  Widget get iconButton => ShareIcon(
        shareIconConfig: imageMessageConfig?.shareIconConfig,
        imageUrl: imageUrl,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          isMessageBySender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (isMessageBySender && !(imageMessageConfig?.hideShareIcon ?? false))
          iconButton,
        Stack(
          children: [
            GestureDetector(
              onTap: () => imageMessageConfig?.onTap != null
                  ? imageMessageConfig?.onTap!(message)
                  : null,
              child: Transform.scale(
                scale: highlightImage ? highlightScale : 1.0,
                alignment: isMessageBySender
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: isMessageBySender
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    borderRadius: imageMessageConfig?.borderRadius ??
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: isMessageBySender
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      width: 3,
                    ),
                  ),
                  // padding: const EdgeInsetsGeometry.all(3),
                  margin: imageMessageConfig?.margin ??
                      EdgeInsets.only(
                        // top: 6,
                        // right: isMessageBySender ? 6 : 0,
                        // left: isMessageBySender ? 0 : 6,
                        bottom: message.reaction.reactions.isNotEmpty ? 15 : 0,
                      ),
                  height: imageMessageConfig?.height ?? 280,
                  width: imageMessageConfig?.width ?? 200,
                  child: Column(
                    children: [
                      Expanded(
                          child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: imageMessageConfig?.height ?? 280,
                                minWidth: imageMessageConfig?.width ?? 200,
                              ),
                              child: buildImage())),
                      const SizedBox(height: 5),
                      Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                              padding: const EdgeInsetsGeometry.only(right: 5),
                              child: buildTimeAndStatus(context))),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
            if (message.reaction.reactions.isNotEmpty)
              ReactionWidget(
                isMessageBySender: isMessageBySender,
                reaction: message.reaction,
                messageReactionConfig: messageReactionConfig,
              ),
          ],
        ),
        if (!isMessageBySender && !(imageMessageConfig?.hideShareIcon ?? false))
          iconButton,
      ],
    );
  }

  Widget buildTimeAndStatus(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 5,
        children: [
          buildTimeText(context),
          if (isMessageBySender)
            ValueListenableBuilder(
              valueListenable: message.statusNotifier,
              builder: (context, status, _) => _getTickIcon(status),
            ),
        ],
      );

  Widget buildTimeText(BuildContext context) => Text(
        TimeOfDay.fromDateTime(
          message.updateAt ?? message.createdAt,
        ).format(context),
        style: imageMessageConfig?.timeTextStyle ??
            TextStyle(
              color: isMessageBySender ? Colors.white70 : Colors.black54,
              fontSize: 12,
            ),
      );

  Icon _getTickIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 16, color: Colors.blue.shade700);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 16, color: Colors.white);
      case MessageStatus.pending:
        return const Icon(Icons.access_time, size: 16, color: Colors.orange);
      case MessageStatus.undelivered:
        return const Icon(Icons.error_outline, size: 16, color: Colors.red);
    }
  }

  ClipRRect buildImage() {
    return ClipRRect(
      borderRadius:
          imageMessageConfig?.borderRadius ?? BorderRadius.circular(14),
      child: (() {
        if (imageUrl.isUrl) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          );
        } else if (imageUrl.fromMemory) {
          return Image.memory(
            base64Decode(imageUrl.substring(imageUrl.indexOf('base64') + 7)),
            fit: BoxFit.cover,
          );
        } else {
          return Image.file(
            File(imageUrl),
            fit: BoxFit.cover,
          );
        }
      }()),
    );
  }
}
