import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Responsive layout wrapper that adapts content based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.maxWidth,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply max width constraint for larger screens
    if (maxWidth != null || Responsive.isDesktop(context)) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.maxContentWidth(context),
        ),
        child: content,
      );
    }

    // Center content if requested
    if (centerContent && (Responsive.isTablet(context) || Responsive.isDesktop(context))) {
      content = Center(child: content);
    }

    // Apply responsive padding
    final padding = Responsive.padding(
      context,
      mobile: mobilePadding ?? Responsive.safeAreaPadding(context),
      tablet: tabletPadding ?? Responsive.safeAreaPadding(context),
      desktop: desktopPadding ?? Responsive.safeAreaPadding(context),
    );

    return Padding(
      padding: padding,
      child: content,
    );
  }
}

/// Responsive grid layout for cards and items
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.columnCount(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Responsive two-column layout (useful for desktop)
class ResponsiveTwoColumn extends StatelessWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double spacing;
  final double breakpoint;
  final int leftFlex;
  final int rightFlex;

  const ResponsiveTwoColumn({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.spacing = 16,
    this.breakpoint = 1024,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < breakpoint) {
      // Stack vertically on smaller screens
      return Column(
        children: [
          leftChild,
          SizedBox(height: spacing),
          rightChild,
        ],
      );
    } else {
      // Side by side on larger screens
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: leftFlex, child: leftChild),
          SizedBox(width: spacing),
          Expanded(flex: rightFlex, child: rightChild),
        ],
      );
    }
  }
}

/// Responsive navigation that adapts to screen size
class ResponsiveNavigation extends StatelessWidget {
  final List<ResponsiveNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const ResponsiveNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      // Bottom navigation for mobile
      return BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemSelected,
        items: items.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
      );
    } else {
      // Side navigation for tablet/desktop
      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onItemSelected,
        labelType: NavigationRailLabelType.all,
        destinations: items.map((item) => NavigationRailDestination(
          icon: Icon(item.icon),
          label: Text(item.label),
        )).toList(),
      );
    }
  }
}

class ResponsiveNavItem {
  final IconData icon;
  final String label;

  const ResponsiveNavItem({
    required this.icon,
    required this.label,
  });
}
