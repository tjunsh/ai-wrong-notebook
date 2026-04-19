import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                color: const Color(0xFFEA580C),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(minimumSize: const Size(120, 40)),
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.description,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String message;
  final String? description;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon ?? Icons.quiz_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
            if (description != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
            if (action != null && actionLabel != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: action,
                style: FilledButton.styleFrom(minimumSize: const Size(120, 40)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message = '加载中...',
    this.icon,
  });

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
          ],
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
