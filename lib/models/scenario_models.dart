class Scenario {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int baseReward;
  final String iconName;
  final String initialNodeId;
  final Map<String, ScenarioNode> nodes;

  Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.baseReward,
    required this.iconName,
    this.initialNodeId = 'start',
    required this.nodes,
  });

  factory Scenario.fromFirestore(Map<String, dynamic> data, String id) {
    final Map<String, dynamic> nodesData = data['nodes'] ?? {};
    final Map<String, ScenarioNode> nodes = nodesData.map(
      (key, value) => MapEntry(key, ScenarioNode.fromMap(value as Map<String, dynamic>, key)),
    );

    return Scenario(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 'Beginner',
      baseReward: data['baseReward'] ?? 50,
      iconName: data['icon'] ?? 'auto_stories',
      initialNodeId: data['initialNodeId'] ?? 'start',
      nodes: nodes,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'baseReward': baseReward,
      'icon': iconName,
      'initialNodeId': initialNodeId,
      'nodes': nodes.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

class ScenarioNode {
  final String id;
  final String text;
  final String? imagePath;
  final List<ScenarioChoice> choices;

  ScenarioNode({
    required this.id,
    required this.text,
    this.imagePath,
    required this.choices,
  });

  factory ScenarioNode.fromMap(Map<String, dynamic> data, String id) {
    final List<dynamic> choicesData = data['choices'] ?? [];
    final List<ScenarioChoice> choices = choicesData
        .map((c) => ScenarioChoice.fromMap(c as Map<String, dynamic>))
        .toList();

    return ScenarioNode(
      id: id,
      text: data['text'] ?? '',
      imagePath: data['imagePath'],
      choices: choices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'imagePath': imagePath,
      'choices': choices.map((c) => c.toMap()).toList(),
    };
  }
}

class ScenarioChoice {
  final String label;
  final String targetNodeId;
  final int xpReward;

  ScenarioChoice({
    required this.label,
    required this.targetNodeId,
    this.xpReward = 0,
  });

  factory ScenarioChoice.fromMap(Map<String, dynamic> data) {
    return ScenarioChoice(
      label: data['label'] ?? '',
      targetNodeId: data['targetNodeId'] ?? 'end',
      xpReward: data['xpReward'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'targetNodeId': targetNodeId,
      'xpReward': xpReward,
    };
  }
}
