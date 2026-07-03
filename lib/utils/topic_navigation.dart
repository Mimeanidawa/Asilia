import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';

void navigateFromTopic(BuildContext context, EducationTopic topic) {
  final app = context.read<AppProvider>();
  switch (topic.linkType) {
    case TopicLinkType.learn:
      app.navigate(AppScreen.learn);
    case TopicLinkType.conditions:
      app.navigate(
        AppScreen.conditions,
        conditionId: topic.linkId,
      );
    case TopicLinkType.askExpert:
      app.navigate(AppScreen.askExpert);
    case TopicLinkType.herb:
      app.navigate(AppScreen.herbDetails, herbId: topic.linkId);
    case TopicLinkType.condition:
      app.navigate(AppScreen.conditions, conditionId: topic.linkId);
  }
}
