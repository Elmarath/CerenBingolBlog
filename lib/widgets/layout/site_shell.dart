import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../config/site_config.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_themes.dart';
import '../../theme/tokens.dart';
import '../cats/cats.dart';
import '../common/bits.dart';

bool _isActive(String location, String path) =>
    path == '/' ? location == '/' : location == path || location.startsWith('$path/');

/// The frame around every page: the nav bar on top, the page below, and a
/// slide-in menu on phones.
class SiteShell extends StatelessWidget {
  const SiteShell({super.key, required this.location, required this.child});

  /// Current path, to highlight the active nav item.
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = ScreenSize.of(context).isCompact;
    return Scaffold(
      endDrawer: compact ? SiteNavDrawer(location: location) : null,
      body: Column(
        children: [
          SiteNavBar(location: location),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class SiteNavBar extends StatelessWidget {
  const SiteNavBar({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = ScreenSize.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: p.background,
        border: Border(bottom: BorderSide(color: p.border, width: 1.5)),
      ),
      padding: EdgeInsets.symmetric(horizontal: size.gutter),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ContentWidths.page),
        child: Row(
          children: [
            // Takes the room the other items leave; the name only shortens when there's none.
            const Expanded(child: Align(alignment: Alignment.centerLeft, child: SiteLogo())),
            const SizedBox(width: Insets.md),
            if (!size.isCompact) ...[
              for (final item in SiteConfig.navItems) ...[
                _NavPill(
                  item: item,
                  active: _isActive(location, item.path),
                  onTap: () => context.go(item.path),
                ),
                const SizedBox(width: 4),
              ],
              const SizedBox(width: Insets.sm),
            ],
            const ThemeMenuButton(),
            if (size.isCompact)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The blinking cat and the blog's name; goes home.
class SiteLogo extends StatelessWidget {
  const SiteLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      link: true,
      label: '${SiteConfig.siteName}, home',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CatFace(size: 42, glasses: true, blinks: true),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SiteConfig.siteName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineSmall?.copyWith(fontSize: 20, height: 1.1),
                    ),
                    Text(
                      'by ${context.content.profile.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(color: p.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatefulWidget {
  const _NavPill({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = widget.active;
    final color = active || _hovered ? p.textPrimary : p.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: ShapeDecoration(
              color: active ? p.accentSoft : (_hovered ? p.surfaceAlt : Colors.transparent),
              shape: StadiumBorder(
                side: BorderSide(color: active ? p.outline : Colors.transparent, width: Strokes.outline),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: _hovered && !active ? -0.04 : 0,
                  duration: Motion.fast,
                  child: Icon(widget.item.icon, size: 18, color: active ? p.accent : color),
                ),
                const SizedBox(width: 7),
                Text(widget.item.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Palette icon listing every theme in `app_themes.dart`.
class ThemeMenuButton extends StatelessWidget {
  const ThemeMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).theme;
    return PopupMenuButton<AppThemePreset>(
      tooltip: 'Theme',
      icon: const Icon(Icons.palette_rounded),
      position: PopupMenuPosition.under,
      onSelected: controller.select,
      itemBuilder: (context) => [
        for (final preset in controller.presets)
          PopupMenuItem(
            value: preset,
            child: Row(
              children: [
                ThemeSwatch(preset: preset),
                const SizedBox(width: 12),
                Expanded(child: Text(preset.name)),
                if (preset.id == controller.current.id) Icon(Icons.check_rounded, size: 18, color: context.palette.accent),
              ],
            ),
          ),
      ],
    );
  }
}

/// A theme's colours in a little circle.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({super.key, required this.preset, this.size = 24});

  final AppThemePreset preset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = preset.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.palette.outline, width: 1.5),
        gradient: SweepGradient(
          colors: [palette.background, palette.background, palette.accent, palette.accent],
          stops: const [0, 0.5, 0.5, 1],
        ),
      ),
    );
  }
}

/// Slide-in menu for phones.
class SiteNavDrawer extends StatelessWidget {
  const SiteNavDrawer({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final controller = AppScope.of(context).theme;
    final text = Theme.of(context).textTheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Insets.md),
          children: [
            const Align(alignment: Alignment.centerLeft, child: SiteLogo()),
            const SizedBox(height: Insets.lg),
            for (final item in SiteConfig.navItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label, style: text.titleMedium),
                  selected: _isActive(location, item.path),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go(item.path);
                  },
                ),
              ),
            const SizedBox(height: Insets.lg),
            Text('THEME', style: text.labelSmall),
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in controller.presets)
                  Pill(
                    label: preset.name,
                    leading: ThemeSwatch(preset: preset, size: 18),
                    selected: preset.id == controller.current.id,
                    onTap: () => controller.select(preset),
                  ),
              ],
            ),
            const SizedBox(height: Insets.xl),
            Row(
              children: [
                Paw(size: 14, color: p.accent),
                const SizedBox(width: 8),
                Expanded(child: Text(SiteConfig.tagline, style: text.bodySmall)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
