import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    this.metadata,
  });

  final Metadata? metadata;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? bannerUrl = metadata?.banner;
    final String? pictureUrl = metadata?.picture;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: <Widget>[
        // Banner defaults to theme.colorScheme.secondary is no banner is set.
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            image: bannerUrl != null && bannerUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(bannerUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),

        // Avatar defaults to gymplyIcon if no avatar is set.
        Positioned(
          bottom: -40,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.surface,
                width: 4,
              ),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: pictureUrl != null && pictureUrl.isNotEmpty
                  ? NetworkImage(pictureUrl)
                  : const AssetImage('assets/icons/gymplyIcon.png'),
            ),
          ),
        ),
      ],
    );
  }
}
