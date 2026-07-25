// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airpass_database.dart';

// ignore_for_file: type=lint
class $NodesTable extends Nodes with TableInfo<$NodesTable, Node> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<int> role = GeneratedColumn<int>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hopCountMeta = const VerificationMeta(
    'hopCount',
  );
  @override
  late final GeneratedColumn<int> hopCount = GeneratedColumn<int>(
    'hop_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batteryLevelMeta = const VerificationMeta(
    'batteryLevel',
  );
  @override
  late final GeneratedColumn<int> batteryLevel = GeneratedColumn<int>(
    'battery_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasInternetAccessMeta = const VerificationMeta(
    'hasInternetAccess',
  );
  @override
  late final GeneratedColumn<bool> hasInternetAccess = GeneratedColumn<bool>(
    'has_internet_access',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_internet_access" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    nodeId,
    role,
    groupId,
    lastSeen,
    hopCount,
    displayName,
    batteryLevel,
    hasInternetAccess,
    metadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Node> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('hop_count')) {
      context.handle(
        _hopCountMeta,
        hopCount.isAcceptableOrUnknown(data['hop_count']!, _hopCountMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('battery_level')) {
      context.handle(
        _batteryLevelMeta,
        batteryLevel.isAcceptableOrUnknown(
          data['battery_level']!,
          _batteryLevelMeta,
        ),
      );
    }
    if (data.containsKey('has_internet_access')) {
      context.handle(
        _hasInternetAccessMeta,
        hasInternetAccess.isAcceptableOrUnknown(
          data['has_internet_access']!,
          _hasInternetAccessMeta,
        ),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeId};
  @override
  Node map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Node(
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}role'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen'],
      )!,
      hopCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hop_count'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      batteryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_level'],
      ),
      hasInternetAccess: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_internet_access'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class Node extends DataClass implements Insertable<Node> {
  /// Unique node identifier (UUID v4, generated on first launch).
  final String nodeId;

  /// The node's mesh role, stored as an integer mapping to [NodeRole].
  final int role;

  /// Optional group affiliation. Null means the node is ungrouped.
  /// Used by [NodeRole.group] nodes for filtered routing.
  final String? groupId;

  /// Epoch milliseconds of the last time this node was encountered
  /// (directly or via gossip).
  final int lastSeen;

  /// How many relay hops away this node was last known to be.
  /// 0 = direct encounter, 1 = one hop away, etc.
  final int hopCount;

  /// Human-readable display name chosen by the user.
  final String? displayName;

  /// Battery level of the node (0-100).
  final int? batteryLevel;

  /// Whether the node has internet access.
  final bool hasInternetAccess;

  /// Extensible JSON blob for future metadata (e.g., capabilities, version).
  final String? metadata;
  const Node({
    required this.nodeId,
    required this.role,
    this.groupId,
    required this.lastSeen,
    required this.hopCount,
    this.displayName,
    this.batteryLevel,
    required this.hasInternetAccess,
    this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_id'] = Variable<String>(nodeId);
    map['role'] = Variable<int>(role);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['last_seen'] = Variable<int>(lastSeen);
    map['hop_count'] = Variable<int>(hopCount);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || batteryLevel != null) {
      map['battery_level'] = Variable<int>(batteryLevel);
    }
    map['has_internet_access'] = Variable<bool>(hasInternetAccess);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      nodeId: Value(nodeId),
      role: Value(role),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      lastSeen: Value(lastSeen),
      hopCount: Value(hopCount),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      batteryLevel: batteryLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryLevel),
      hasInternetAccess: Value(hasInternetAccess),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory Node.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Node(
      nodeId: serializer.fromJson<String>(json['nodeId']),
      role: serializer.fromJson<int>(json['role']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
      hopCount: serializer.fromJson<int>(json['hopCount']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      batteryLevel: serializer.fromJson<int?>(json['batteryLevel']),
      hasInternetAccess: serializer.fromJson<bool>(json['hasInternetAccess']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeId': serializer.toJson<String>(nodeId),
      'role': serializer.toJson<int>(role),
      'groupId': serializer.toJson<String?>(groupId),
      'lastSeen': serializer.toJson<int>(lastSeen),
      'hopCount': serializer.toJson<int>(hopCount),
      'displayName': serializer.toJson<String?>(displayName),
      'batteryLevel': serializer.toJson<int?>(batteryLevel),
      'hasInternetAccess': serializer.toJson<bool>(hasInternetAccess),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  Node copyWith({
    String? nodeId,
    int? role,
    Value<String?> groupId = const Value.absent(),
    int? lastSeen,
    int? hopCount,
    Value<String?> displayName = const Value.absent(),
    Value<int?> batteryLevel = const Value.absent(),
    bool? hasInternetAccess,
    Value<String?> metadata = const Value.absent(),
  }) => Node(
    nodeId: nodeId ?? this.nodeId,
    role: role ?? this.role,
    groupId: groupId.present ? groupId.value : this.groupId,
    lastSeen: lastSeen ?? this.lastSeen,
    hopCount: hopCount ?? this.hopCount,
    displayName: displayName.present ? displayName.value : this.displayName,
    batteryLevel: batteryLevel.present ? batteryLevel.value : this.batteryLevel,
    hasInternetAccess: hasInternetAccess ?? this.hasInternetAccess,
    metadata: metadata.present ? metadata.value : this.metadata,
  );
  Node copyWithCompanion(NodesCompanion data) {
    return Node(
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      role: data.role.present ? data.role.value : this.role,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      hopCount: data.hopCount.present ? data.hopCount.value : this.hopCount,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      batteryLevel: data.batteryLevel.present
          ? data.batteryLevel.value
          : this.batteryLevel,
      hasInternetAccess: data.hasInternetAccess.present
          ? data.hasInternetAccess.value
          : this.hasInternetAccess,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Node(')
          ..write('nodeId: $nodeId, ')
          ..write('role: $role, ')
          ..write('groupId: $groupId, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('hopCount: $hopCount, ')
          ..write('displayName: $displayName, ')
          ..write('batteryLevel: $batteryLevel, ')
          ..write('hasInternetAccess: $hasInternetAccess, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    nodeId,
    role,
    groupId,
    lastSeen,
    hopCount,
    displayName,
    batteryLevel,
    hasInternetAccess,
    metadata,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          other.nodeId == this.nodeId &&
          other.role == this.role &&
          other.groupId == this.groupId &&
          other.lastSeen == this.lastSeen &&
          other.hopCount == this.hopCount &&
          other.displayName == this.displayName &&
          other.batteryLevel == this.batteryLevel &&
          other.hasInternetAccess == this.hasInternetAccess &&
          other.metadata == this.metadata);
}

class NodesCompanion extends UpdateCompanion<Node> {
  final Value<String> nodeId;
  final Value<int> role;
  final Value<String?> groupId;
  final Value<int> lastSeen;
  final Value<int> hopCount;
  final Value<String?> displayName;
  final Value<int?> batteryLevel;
  final Value<bool> hasInternetAccess;
  final Value<String?> metadata;
  final Value<int> rowid;
  const NodesCompanion({
    this.nodeId = const Value.absent(),
    this.role = const Value.absent(),
    this.groupId = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.hopCount = const Value.absent(),
    this.displayName = const Value.absent(),
    this.batteryLevel = const Value.absent(),
    this.hasInternetAccess = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodesCompanion.insert({
    required String nodeId,
    this.role = const Value.absent(),
    this.groupId = const Value.absent(),
    required int lastSeen,
    this.hopCount = const Value.absent(),
    this.displayName = const Value.absent(),
    this.batteryLevel = const Value.absent(),
    this.hasInternetAccess = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : nodeId = Value(nodeId),
       lastSeen = Value(lastSeen);
  static Insertable<Node> custom({
    Expression<String>? nodeId,
    Expression<int>? role,
    Expression<String>? groupId,
    Expression<int>? lastSeen,
    Expression<int>? hopCount,
    Expression<String>? displayName,
    Expression<int>? batteryLevel,
    Expression<bool>? hasInternetAccess,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeId != null) 'node_id': nodeId,
      if (role != null) 'role': role,
      if (groupId != null) 'group_id': groupId,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (hopCount != null) 'hop_count': hopCount,
      if (displayName != null) 'display_name': displayName,
      if (batteryLevel != null) 'battery_level': batteryLevel,
      if (hasInternetAccess != null) 'has_internet_access': hasInternetAccess,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodesCompanion copyWith({
    Value<String>? nodeId,
    Value<int>? role,
    Value<String?>? groupId,
    Value<int>? lastSeen,
    Value<int>? hopCount,
    Value<String?>? displayName,
    Value<int?>? batteryLevel,
    Value<bool>? hasInternetAccess,
    Value<String?>? metadata,
    Value<int>? rowid,
  }) {
    return NodesCompanion(
      nodeId: nodeId ?? this.nodeId,
      role: role ?? this.role,
      groupId: groupId ?? this.groupId,
      lastSeen: lastSeen ?? this.lastSeen,
      hopCount: hopCount ?? this.hopCount,
      displayName: displayName ?? this.displayName,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      hasInternetAccess: hasInternetAccess ?? this.hasInternetAccess,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(role.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<int>(lastSeen.value);
    }
    if (hopCount.present) {
      map['hop_count'] = Variable<int>(hopCount.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (batteryLevel.present) {
      map['battery_level'] = Variable<int>(batteryLevel.value);
    }
    if (hasInternetAccess.present) {
      map['has_internet_access'] = Variable<bool>(hasInternetAccess.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('nodeId: $nodeId, ')
          ..write('role: $role, ')
          ..write('groupId: $groupId, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('hopCount: $hopCount, ')
          ..write('displayName: $displayName, ')
          ..write('batteryLevel: $batteryLevel, ')
          ..write('hasInternetAccess: $hasInternetAccess, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(MessageStatus.pending.value),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ttlMeta = const VerificationMeta('ttl');
  @override
  late final GeneratedColumn<int> ttl = GeneratedColumn<int>(
    'ttl',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<int> mediaType = GeneratedColumn<int>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mediaFileNameMeta = const VerificationMeta(
    'mediaFileName',
  );
  @override
  late final GeneratedColumn<String> mediaFileName = GeneratedColumn<String>(
    'media_file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaMimeTypeMeta = const VerificationMeta(
    'mediaMimeType',
  );
  @override
  late final GeneratedColumn<String> mediaMimeType = GeneratedColumn<String>(
    'media_mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaFileSizeMeta = const VerificationMeta(
    'mediaFileSize',
  );
  @override
  late final GeneratedColumn<int> mediaFileSize = GeneratedColumn<int>(
    'media_file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaHashMeta = const VerificationMeta(
    'mediaHash',
  );
  @override
  late final GeneratedColumn<String> mediaHash = GeneratedColumn<String>(
    'media_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaLocalPathMeta = const VerificationMeta(
    'mediaLocalPath',
  );
  @override
  late final GeneratedColumn<String> mediaLocalPath = GeneratedColumn<String>(
    'media_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaAvailabilityMeta = const VerificationMeta(
    'mediaAvailability',
  );
  @override
  late final GeneratedColumn<int> mediaAvailability = GeneratedColumn<int>(
    'media_availability',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mediaThumbnailMeta = const VerificationMeta(
    'mediaThumbnail',
  );
  @override
  late final GeneratedColumn<Uint8List> mediaThumbnail =
      GeneratedColumn<Uint8List>(
        'media_thumbnail',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    senderId,
    targetId,
    payload,
    status,
    createdAt,
    ttl,
    signature,
    mediaType,
    mediaFileName,
    mediaMimeType,
    mediaFileSize,
    mediaHash,
    mediaLocalPath,
    mediaAvailability,
    mediaThumbnail,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('ttl')) {
      context.handle(
        _ttlMeta,
        ttl.isAcceptableOrUnknown(data['ttl']!, _ttlMeta),
      );
    } else if (isInserting) {
      context.missing(_ttlMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    }
    if (data.containsKey('media_file_name')) {
      context.handle(
        _mediaFileNameMeta,
        mediaFileName.isAcceptableOrUnknown(
          data['media_file_name']!,
          _mediaFileNameMeta,
        ),
      );
    }
    if (data.containsKey('media_mime_type')) {
      context.handle(
        _mediaMimeTypeMeta,
        mediaMimeType.isAcceptableOrUnknown(
          data['media_mime_type']!,
          _mediaMimeTypeMeta,
        ),
      );
    }
    if (data.containsKey('media_file_size')) {
      context.handle(
        _mediaFileSizeMeta,
        mediaFileSize.isAcceptableOrUnknown(
          data['media_file_size']!,
          _mediaFileSizeMeta,
        ),
      );
    }
    if (data.containsKey('media_hash')) {
      context.handle(
        _mediaHashMeta,
        mediaHash.isAcceptableOrUnknown(data['media_hash']!, _mediaHashMeta),
      );
    }
    if (data.containsKey('media_local_path')) {
      context.handle(
        _mediaLocalPathMeta,
        mediaLocalPath.isAcceptableOrUnknown(
          data['media_local_path']!,
          _mediaLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('media_availability')) {
      context.handle(
        _mediaAvailabilityMeta,
        mediaAvailability.isAcceptableOrUnknown(
          data['media_availability']!,
          _mediaAvailabilityMeta,
        ),
      );
    }
    if (data.containsKey('media_thumbnail')) {
      context.handle(
        _mediaThumbnailMeta,
        mediaThumbnail.isAcceptableOrUnknown(
          data['media_thumbnail']!,
          _mediaThumbnailMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      ttl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ttl'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_type'],
      )!,
      mediaFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_file_name'],
      ),
      mediaMimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_mime_type'],
      ),
      mediaFileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_file_size'],
      ),
      mediaHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_hash'],
      ),
      mediaLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_local_path'],
      ),
      mediaAvailability: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_availability'],
      )!,
      mediaThumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}media_thumbnail'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  /// Globally unique message identifier (UUID v4).
  final String messageId;

  /// The originating node's ID.
  final String senderId;

  /// The destination node's ID. Use '*' for broadcast messages.
  final String targetId;

  /// The encoded message content (arbitrary bytes).
  final Uint8List payload;

  /// Delivery status, stored as an integer mapping to [MessageStatus].
  final int status;

  /// Epoch milliseconds when the message was originally created.
  final int createdAt;

  /// Remaining hop budget. Decremented on each relay.
  /// When this reaches 0, the message is marked [MessageStatus.expired].
  final int ttl;

  /// Optional HMAC-SHA256 signature for message integrity verification.
  /// Computed by [MessageSigner] when the message is created locally.
  /// Relaying nodes can verify the signature to detect tampering.
  final String? signature;

  /// The type of media attached (0 = text, 1 = image, 2 = video, etc.).
  /// See [MediaType]. Defaults to 0 (text — no media).
  final int mediaType;

  /// Original filename of the attached media (e.g., 'photo_001.jpg').
  /// Null for text-only messages.
  final String? mediaFileName;

  /// MIME type of the media (e.g., 'image/jpeg', 'video/mp4').
  /// Null for text-only messages.
  final String? mediaMimeType;

  /// Size of the full media file in bytes.
  /// Used by the UI to display file size and decide auto-download.
  final int? mediaFileSize;

  /// SHA-256 hash of the full media file for integrity verification.
  /// Computed on send, verified on receive after FILE transfer.
  final String? mediaHash;

  /// Local filesystem path to the downloaded media binary.
  /// Null until the binary is successfully transferred.
  final String? mediaLocalPath;

  /// Availability state of the media binary on this device.
  /// See [MediaAvailability]. Defaults to 0 (notApplicable — text message).
  final int mediaAvailability;

  /// Compressed thumbnail bytes (JPEG, ≤5 KB) for instant preview.
  /// Embedded directly in the epidemic sync payload so users see
  /// a preview even before the full file is transferred.
  final Uint8List? mediaThumbnail;
  const Message({
    required this.messageId,
    required this.senderId,
    required this.targetId,
    required this.payload,
    required this.status,
    required this.createdAt,
    required this.ttl,
    this.signature,
    required this.mediaType,
    this.mediaFileName,
    this.mediaMimeType,
    this.mediaFileSize,
    this.mediaHash,
    this.mediaLocalPath,
    required this.mediaAvailability,
    this.mediaThumbnail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['sender_id'] = Variable<String>(senderId);
    map['target_id'] = Variable<String>(targetId);
    map['payload'] = Variable<Uint8List>(payload);
    map['status'] = Variable<int>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['ttl'] = Variable<int>(ttl);
    if (!nullToAbsent || signature != null) {
      map['signature'] = Variable<String>(signature);
    }
    map['media_type'] = Variable<int>(mediaType);
    if (!nullToAbsent || mediaFileName != null) {
      map['media_file_name'] = Variable<String>(mediaFileName);
    }
    if (!nullToAbsent || mediaMimeType != null) {
      map['media_mime_type'] = Variable<String>(mediaMimeType);
    }
    if (!nullToAbsent || mediaFileSize != null) {
      map['media_file_size'] = Variable<int>(mediaFileSize);
    }
    if (!nullToAbsent || mediaHash != null) {
      map['media_hash'] = Variable<String>(mediaHash);
    }
    if (!nullToAbsent || mediaLocalPath != null) {
      map['media_local_path'] = Variable<String>(mediaLocalPath);
    }
    map['media_availability'] = Variable<int>(mediaAvailability);
    if (!nullToAbsent || mediaThumbnail != null) {
      map['media_thumbnail'] = Variable<Uint8List>(mediaThumbnail);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      messageId: Value(messageId),
      senderId: Value(senderId),
      targetId: Value(targetId),
      payload: Value(payload),
      status: Value(status),
      createdAt: Value(createdAt),
      ttl: Value(ttl),
      signature: signature == null && nullToAbsent
          ? const Value.absent()
          : Value(signature),
      mediaType: Value(mediaType),
      mediaFileName: mediaFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaFileName),
      mediaMimeType: mediaMimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaMimeType),
      mediaFileSize: mediaFileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaFileSize),
      mediaHash: mediaHash == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaHash),
      mediaLocalPath: mediaLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaLocalPath),
      mediaAvailability: Value(mediaAvailability),
      mediaThumbnail: mediaThumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaThumbnail),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      messageId: serializer.fromJson<String>(json['messageId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      targetId: serializer.fromJson<String>(json['targetId']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      ttl: serializer.fromJson<int>(json['ttl']),
      signature: serializer.fromJson<String?>(json['signature']),
      mediaType: serializer.fromJson<int>(json['mediaType']),
      mediaFileName: serializer.fromJson<String?>(json['mediaFileName']),
      mediaMimeType: serializer.fromJson<String?>(json['mediaMimeType']),
      mediaFileSize: serializer.fromJson<int?>(json['mediaFileSize']),
      mediaHash: serializer.fromJson<String?>(json['mediaHash']),
      mediaLocalPath: serializer.fromJson<String?>(json['mediaLocalPath']),
      mediaAvailability: serializer.fromJson<int>(json['mediaAvailability']),
      mediaThumbnail: serializer.fromJson<Uint8List?>(json['mediaThumbnail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'senderId': serializer.toJson<String>(senderId),
      'targetId': serializer.toJson<String>(targetId),
      'payload': serializer.toJson<Uint8List>(payload),
      'status': serializer.toJson<int>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'ttl': serializer.toJson<int>(ttl),
      'signature': serializer.toJson<String?>(signature),
      'mediaType': serializer.toJson<int>(mediaType),
      'mediaFileName': serializer.toJson<String?>(mediaFileName),
      'mediaMimeType': serializer.toJson<String?>(mediaMimeType),
      'mediaFileSize': serializer.toJson<int?>(mediaFileSize),
      'mediaHash': serializer.toJson<String?>(mediaHash),
      'mediaLocalPath': serializer.toJson<String?>(mediaLocalPath),
      'mediaAvailability': serializer.toJson<int>(mediaAvailability),
      'mediaThumbnail': serializer.toJson<Uint8List?>(mediaThumbnail),
    };
  }

  Message copyWith({
    String? messageId,
    String? senderId,
    String? targetId,
    Uint8List? payload,
    int? status,
    int? createdAt,
    int? ttl,
    Value<String?> signature = const Value.absent(),
    int? mediaType,
    Value<String?> mediaFileName = const Value.absent(),
    Value<String?> mediaMimeType = const Value.absent(),
    Value<int?> mediaFileSize = const Value.absent(),
    Value<String?> mediaHash = const Value.absent(),
    Value<String?> mediaLocalPath = const Value.absent(),
    int? mediaAvailability,
    Value<Uint8List?> mediaThumbnail = const Value.absent(),
  }) => Message(
    messageId: messageId ?? this.messageId,
    senderId: senderId ?? this.senderId,
    targetId: targetId ?? this.targetId,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    ttl: ttl ?? this.ttl,
    signature: signature.present ? signature.value : this.signature,
    mediaType: mediaType ?? this.mediaType,
    mediaFileName: mediaFileName.present
        ? mediaFileName.value
        : this.mediaFileName,
    mediaMimeType: mediaMimeType.present
        ? mediaMimeType.value
        : this.mediaMimeType,
    mediaFileSize: mediaFileSize.present
        ? mediaFileSize.value
        : this.mediaFileSize,
    mediaHash: mediaHash.present ? mediaHash.value : this.mediaHash,
    mediaLocalPath: mediaLocalPath.present
        ? mediaLocalPath.value
        : this.mediaLocalPath,
    mediaAvailability: mediaAvailability ?? this.mediaAvailability,
    mediaThumbnail: mediaThumbnail.present
        ? mediaThumbnail.value
        : this.mediaThumbnail,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      ttl: data.ttl.present ? data.ttl.value : this.ttl,
      signature: data.signature.present ? data.signature.value : this.signature,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      mediaFileName: data.mediaFileName.present
          ? data.mediaFileName.value
          : this.mediaFileName,
      mediaMimeType: data.mediaMimeType.present
          ? data.mediaMimeType.value
          : this.mediaMimeType,
      mediaFileSize: data.mediaFileSize.present
          ? data.mediaFileSize.value
          : this.mediaFileSize,
      mediaHash: data.mediaHash.present ? data.mediaHash.value : this.mediaHash,
      mediaLocalPath: data.mediaLocalPath.present
          ? data.mediaLocalPath.value
          : this.mediaLocalPath,
      mediaAvailability: data.mediaAvailability.present
          ? data.mediaAvailability.value
          : this.mediaAvailability,
      mediaThumbnail: data.mediaThumbnail.present
          ? data.mediaThumbnail.value
          : this.mediaThumbnail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('targetId: $targetId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('ttl: $ttl, ')
          ..write('signature: $signature, ')
          ..write('mediaType: $mediaType, ')
          ..write('mediaFileName: $mediaFileName, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaFileSize: $mediaFileSize, ')
          ..write('mediaHash: $mediaHash, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('mediaAvailability: $mediaAvailability, ')
          ..write('mediaThumbnail: $mediaThumbnail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    senderId,
    targetId,
    $driftBlobEquality.hash(payload),
    status,
    createdAt,
    ttl,
    signature,
    mediaType,
    mediaFileName,
    mediaMimeType,
    mediaFileSize,
    mediaHash,
    mediaLocalPath,
    mediaAvailability,
    $driftBlobEquality.hash(mediaThumbnail),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.messageId == this.messageId &&
          other.senderId == this.senderId &&
          other.targetId == this.targetId &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.ttl == this.ttl &&
          other.signature == this.signature &&
          other.mediaType == this.mediaType &&
          other.mediaFileName == this.mediaFileName &&
          other.mediaMimeType == this.mediaMimeType &&
          other.mediaFileSize == this.mediaFileSize &&
          other.mediaHash == this.mediaHash &&
          other.mediaLocalPath == this.mediaLocalPath &&
          other.mediaAvailability == this.mediaAvailability &&
          $driftBlobEquality.equals(other.mediaThumbnail, this.mediaThumbnail));
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> messageId;
  final Value<String> senderId;
  final Value<String> targetId;
  final Value<Uint8List> payload;
  final Value<int> status;
  final Value<int> createdAt;
  final Value<int> ttl;
  final Value<String?> signature;
  final Value<int> mediaType;
  final Value<String?> mediaFileName;
  final Value<String?> mediaMimeType;
  final Value<int?> mediaFileSize;
  final Value<String?> mediaHash;
  final Value<String?> mediaLocalPath;
  final Value<int> mediaAvailability;
  final Value<Uint8List?> mediaThumbnail;
  final Value<int> rowid;
  const MessagesCompanion({
    this.messageId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ttl = const Value.absent(),
    this.signature = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.mediaFileName = const Value.absent(),
    this.mediaMimeType = const Value.absent(),
    this.mediaFileSize = const Value.absent(),
    this.mediaHash = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.mediaAvailability = const Value.absent(),
    this.mediaThumbnail = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String messageId,
    required String senderId,
    required String targetId,
    required Uint8List payload,
    this.status = const Value.absent(),
    required int createdAt,
    required int ttl,
    this.signature = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.mediaFileName = const Value.absent(),
    this.mediaMimeType = const Value.absent(),
    this.mediaFileSize = const Value.absent(),
    this.mediaHash = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.mediaAvailability = const Value.absent(),
    this.mediaThumbnail = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       senderId = Value(senderId),
       targetId = Value(targetId),
       payload = Value(payload),
       createdAt = Value(createdAt),
       ttl = Value(ttl);
  static Insertable<Message> custom({
    Expression<String>? messageId,
    Expression<String>? senderId,
    Expression<String>? targetId,
    Expression<Uint8List>? payload,
    Expression<int>? status,
    Expression<int>? createdAt,
    Expression<int>? ttl,
    Expression<String>? signature,
    Expression<int>? mediaType,
    Expression<String>? mediaFileName,
    Expression<String>? mediaMimeType,
    Expression<int>? mediaFileSize,
    Expression<String>? mediaHash,
    Expression<String>? mediaLocalPath,
    Expression<int>? mediaAvailability,
    Expression<Uint8List>? mediaThumbnail,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (senderId != null) 'sender_id': senderId,
      if (targetId != null) 'target_id': targetId,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (ttl != null) 'ttl': ttl,
      if (signature != null) 'signature': signature,
      if (mediaType != null) 'media_type': mediaType,
      if (mediaFileName != null) 'media_file_name': mediaFileName,
      if (mediaMimeType != null) 'media_mime_type': mediaMimeType,
      if (mediaFileSize != null) 'media_file_size': mediaFileSize,
      if (mediaHash != null) 'media_hash': mediaHash,
      if (mediaLocalPath != null) 'media_local_path': mediaLocalPath,
      if (mediaAvailability != null) 'media_availability': mediaAvailability,
      if (mediaThumbnail != null) 'media_thumbnail': mediaThumbnail,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? senderId,
    Value<String>? targetId,
    Value<Uint8List>? payload,
    Value<int>? status,
    Value<int>? createdAt,
    Value<int>? ttl,
    Value<String?>? signature,
    Value<int>? mediaType,
    Value<String?>? mediaFileName,
    Value<String?>? mediaMimeType,
    Value<int?>? mediaFileSize,
    Value<String?>? mediaHash,
    Value<String?>? mediaLocalPath,
    Value<int>? mediaAvailability,
    Value<Uint8List?>? mediaThumbnail,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      targetId: targetId ?? this.targetId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      ttl: ttl ?? this.ttl,
      signature: signature ?? this.signature,
      mediaType: mediaType ?? this.mediaType,
      mediaFileName: mediaFileName ?? this.mediaFileName,
      mediaMimeType: mediaMimeType ?? this.mediaMimeType,
      mediaFileSize: mediaFileSize ?? this.mediaFileSize,
      mediaHash: mediaHash ?? this.mediaHash,
      mediaLocalPath: mediaLocalPath ?? this.mediaLocalPath,
      mediaAvailability: mediaAvailability ?? this.mediaAvailability,
      mediaThumbnail: mediaThumbnail ?? this.mediaThumbnail,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (ttl.present) {
      map['ttl'] = Variable<int>(ttl.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<int>(mediaType.value);
    }
    if (mediaFileName.present) {
      map['media_file_name'] = Variable<String>(mediaFileName.value);
    }
    if (mediaMimeType.present) {
      map['media_mime_type'] = Variable<String>(mediaMimeType.value);
    }
    if (mediaFileSize.present) {
      map['media_file_size'] = Variable<int>(mediaFileSize.value);
    }
    if (mediaHash.present) {
      map['media_hash'] = Variable<String>(mediaHash.value);
    }
    if (mediaLocalPath.present) {
      map['media_local_path'] = Variable<String>(mediaLocalPath.value);
    }
    if (mediaAvailability.present) {
      map['media_availability'] = Variable<int>(mediaAvailability.value);
    }
    if (mediaThumbnail.present) {
      map['media_thumbnail'] = Variable<Uint8List>(mediaThumbnail.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('targetId: $targetId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('ttl: $ttl, ')
          ..write('signature: $signature, ')
          ..write('mediaType: $mediaType, ')
          ..write('mediaFileName: $mediaFileName, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaFileSize: $mediaFileSize, ')
          ..write('mediaHash: $mediaHash, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('mediaAvailability: $mediaAvailability, ')
          ..write('mediaThumbnail: $mediaThumbnail, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discoveredAtMeta = const VerificationMeta(
    'discoveredAt',
  );
  @override
  late final GeneratedColumn<int> discoveredAt = GeneratedColumn<int>(
    'discovered_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta(
    'memberCount',
  );
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isSubscribedMeta = const VerificationMeta(
    'isSubscribed',
  );
  @override
  late final GeneratedColumn<bool> isSubscribed = GeneratedColumn<bool>(
    'is_subscribed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_subscribed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    displayName,
    discoveredAt,
    lastSeenAt,
    memberCount,
    isSubscribed,
    metadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Group> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('discovered_at')) {
      context.handle(
        _discoveredAtMeta,
        discoveredAt.isAcceptableOrUnknown(
          data['discovered_at']!,
          _discoveredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discoveredAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('member_count')) {
      context.handle(
        _memberCountMeta,
        memberCount.isAcceptableOrUnknown(
          data['member_count']!,
          _memberCountMeta,
        ),
      );
    }
    if (data.containsKey('is_subscribed')) {
      context.handle(
        _isSubscribedMeta,
        isSubscribed.isAcceptableOrUnknown(
          data['is_subscribed']!,
          _isSubscribedMeta,
        ),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      discoveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discovered_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      )!,
      memberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_count'],
      )!,
      isSubscribed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_subscribed'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  /// Unique group identifier string (e.g., 'protest-2026', 'aid-sector-5').
  final String groupId;

  /// Human-readable display name for the group.
  /// May be the same as [groupId] when first discovered; can be updated later.
  final String displayName;

  /// Epoch milliseconds when this group was first discovered.
  final int discoveredAt;

  /// Epoch milliseconds of the last time a node advertising this group
  /// was encountered (directly or via gossip).
  final int lastSeenAt;

  /// Number of distinct nodes currently known to belong to this group.
  /// Updated during sync merges for UI display (e.g., "12 members").
  final int memberCount;

  /// Whether the local node is subscribed (actively participating) in
  /// this group. Only one group can be active at a time for
  /// [NodeRole.group] nodes.
  final bool isSubscribed;

  /// Extensible JSON blob for future metadata (e.g., description, icon).
  final String? metadata;
  const Group({
    required this.groupId,
    required this.displayName,
    required this.discoveredAt,
    required this.lastSeenAt,
    required this.memberCount,
    required this.isSubscribed,
    this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['display_name'] = Variable<String>(displayName);
    map['discovered_at'] = Variable<int>(discoveredAt);
    map['last_seen_at'] = Variable<int>(lastSeenAt);
    map['member_count'] = Variable<int>(memberCount);
    map['is_subscribed'] = Variable<bool>(isSubscribed);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      groupId: Value(groupId),
      displayName: Value(displayName),
      discoveredAt: Value(discoveredAt),
      lastSeenAt: Value(lastSeenAt),
      memberCount: Value(memberCount),
      isSubscribed: Value(isSubscribed),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      groupId: serializer.fromJson<String>(json['groupId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      discoveredAt: serializer.fromJson<int>(json['discoveredAt']),
      lastSeenAt: serializer.fromJson<int>(json['lastSeenAt']),
      memberCount: serializer.fromJson<int>(json['memberCount']),
      isSubscribed: serializer.fromJson<bool>(json['isSubscribed']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'displayName': serializer.toJson<String>(displayName),
      'discoveredAt': serializer.toJson<int>(discoveredAt),
      'lastSeenAt': serializer.toJson<int>(lastSeenAt),
      'memberCount': serializer.toJson<int>(memberCount),
      'isSubscribed': serializer.toJson<bool>(isSubscribed),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  Group copyWith({
    String? groupId,
    String? displayName,
    int? discoveredAt,
    int? lastSeenAt,
    int? memberCount,
    bool? isSubscribed,
    Value<String?> metadata = const Value.absent(),
  }) => Group(
    groupId: groupId ?? this.groupId,
    displayName: displayName ?? this.displayName,
    discoveredAt: discoveredAt ?? this.discoveredAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    memberCount: memberCount ?? this.memberCount,
    isSubscribed: isSubscribed ?? this.isSubscribed,
    metadata: metadata.present ? metadata.value : this.metadata,
  );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      discoveredAt: data.discoveredAt.present
          ? data.discoveredAt.value
          : this.discoveredAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      memberCount: data.memberCount.present
          ? data.memberCount.value
          : this.memberCount,
      isSubscribed: data.isSubscribed.present
          ? data.isSubscribed.value
          : this.isSubscribed,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('groupId: $groupId, ')
          ..write('displayName: $displayName, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('memberCount: $memberCount, ')
          ..write('isSubscribed: $isSubscribed, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    displayName,
    discoveredAt,
    lastSeenAt,
    memberCount,
    isSubscribed,
    metadata,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.groupId == this.groupId &&
          other.displayName == this.displayName &&
          other.discoveredAt == this.discoveredAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.memberCount == this.memberCount &&
          other.isSubscribed == this.isSubscribed &&
          other.metadata == this.metadata);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<String> groupId;
  final Value<String> displayName;
  final Value<int> discoveredAt;
  final Value<int> lastSeenAt;
  final Value<int> memberCount;
  final Value<bool> isSubscribed;
  final Value<String?> metadata;
  final Value<int> rowid;
  const GroupsCompanion({
    this.groupId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.isSubscribed = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String groupId,
    required String displayName,
    required int discoveredAt,
    required int lastSeenAt,
    this.memberCount = const Value.absent(),
    this.isSubscribed = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       displayName = Value(displayName),
       discoveredAt = Value(discoveredAt),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<Group> custom({
    Expression<String>? groupId,
    Expression<String>? displayName,
    Expression<int>? discoveredAt,
    Expression<int>? lastSeenAt,
    Expression<int>? memberCount,
    Expression<bool>? isSubscribed,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (displayName != null) 'display_name': displayName,
      if (discoveredAt != null) 'discovered_at': discoveredAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (memberCount != null) 'member_count': memberCount,
      if (isSubscribed != null) 'is_subscribed': isSubscribed,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<String>? groupId,
    Value<String>? displayName,
    Value<int>? discoveredAt,
    Value<int>? lastSeenAt,
    Value<int>? memberCount,
    Value<bool>? isSubscribed,
    Value<String?>? metadata,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      memberCount: memberCount ?? this.memberCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (discoveredAt.present) {
      map['discovered_at'] = Variable<int>(discoveredAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (isSubscribed.present) {
      map['is_subscribed'] = Variable<bool>(isSubscribed.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('displayName: $displayName, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('memberCount: $memberCount, ')
          ..write('isSubscribed: $isSubscribed, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageDeliveriesTable extends MessageDeliveries
    with TableInfo<$MessageDeliveriesTable, MessageDelivery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageDeliveriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerNodeIdMeta = const VerificationMeta(
    'peerNodeId',
  );
  @override
  late final GeneratedColumn<String> peerNodeId = GeneratedColumn<String>(
    'peer_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<int> deliveredAt = GeneratedColumn<int>(
    'delivered_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [messageId, peerNodeId, deliveredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_deliveries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageDelivery> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('peer_node_id')) {
      context.handle(
        _peerNodeIdMeta,
        peerNodeId.isAcceptableOrUnknown(
          data['peer_node_id']!,
          _peerNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerNodeIdMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, peerNodeId};
  @override
  MessageDelivery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageDelivery(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      peerNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_node_id'],
      )!,
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delivered_at'],
      )!,
    );
  }

  @override
  $MessageDeliveriesTable createAlias(String alias) {
    return $MessageDeliveriesTable(attachedDatabase, alias);
  }
}

class MessageDelivery extends DataClass implements Insertable<MessageDelivery> {
  /// The message that was delivered.
  final String messageId;

  /// The peer node that received this message.
  final String peerNodeId;

  /// Epoch milliseconds when the delivery occurred.
  final int deliveredAt;
  const MessageDelivery({
    required this.messageId,
    required this.peerNodeId,
    required this.deliveredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['peer_node_id'] = Variable<String>(peerNodeId);
    map['delivered_at'] = Variable<int>(deliveredAt);
    return map;
  }

  MessageDeliveriesCompanion toCompanion(bool nullToAbsent) {
    return MessageDeliveriesCompanion(
      messageId: Value(messageId),
      peerNodeId: Value(peerNodeId),
      deliveredAt: Value(deliveredAt),
    );
  }

  factory MessageDelivery.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageDelivery(
      messageId: serializer.fromJson<String>(json['messageId']),
      peerNodeId: serializer.fromJson<String>(json['peerNodeId']),
      deliveredAt: serializer.fromJson<int>(json['deliveredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'peerNodeId': serializer.toJson<String>(peerNodeId),
      'deliveredAt': serializer.toJson<int>(deliveredAt),
    };
  }

  MessageDelivery copyWith({
    String? messageId,
    String? peerNodeId,
    int? deliveredAt,
  }) => MessageDelivery(
    messageId: messageId ?? this.messageId,
    peerNodeId: peerNodeId ?? this.peerNodeId,
    deliveredAt: deliveredAt ?? this.deliveredAt,
  );
  MessageDelivery copyWithCompanion(MessageDeliveriesCompanion data) {
    return MessageDelivery(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      peerNodeId: data.peerNodeId.present
          ? data.peerNodeId.value
          : this.peerNodeId,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageDelivery(')
          ..write('messageId: $messageId, ')
          ..write('peerNodeId: $peerNodeId, ')
          ..write('deliveredAt: $deliveredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, peerNodeId, deliveredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageDelivery &&
          other.messageId == this.messageId &&
          other.peerNodeId == this.peerNodeId &&
          other.deliveredAt == this.deliveredAt);
}

class MessageDeliveriesCompanion extends UpdateCompanion<MessageDelivery> {
  final Value<String> messageId;
  final Value<String> peerNodeId;
  final Value<int> deliveredAt;
  final Value<int> rowid;
  const MessageDeliveriesCompanion({
    this.messageId = const Value.absent(),
    this.peerNodeId = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageDeliveriesCompanion.insert({
    required String messageId,
    required String peerNodeId,
    required int deliveredAt,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       peerNodeId = Value(peerNodeId),
       deliveredAt = Value(deliveredAt);
  static Insertable<MessageDelivery> custom({
    Expression<String>? messageId,
    Expression<String>? peerNodeId,
    Expression<int>? deliveredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (peerNodeId != null) 'peer_node_id': peerNodeId,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageDeliveriesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? peerNodeId,
    Value<int>? deliveredAt,
    Value<int>? rowid,
  }) {
    return MessageDeliveriesCompanion(
      messageId: messageId ?? this.messageId,
      peerNodeId: peerNodeId ?? this.peerNodeId,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (peerNodeId.present) {
      map['peer_node_id'] = Variable<String>(peerNodeId.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<int>(deliveredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageDeliveriesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('peerNodeId: $peerNodeId, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AirpassDatabase extends GeneratedDatabase {
  _$AirpassDatabase(QueryExecutor e) : super(e);
  $AirpassDatabaseManager get managers => $AirpassDatabaseManager(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $MessageDeliveriesTable messageDeliveries =
      $MessageDeliveriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    nodes,
    messages,
    groups,
    messageDeliveries,
  ];
}

typedef $$NodesTableCreateCompanionBuilder =
    NodesCompanion Function({
      required String nodeId,
      Value<int> role,
      Value<String?> groupId,
      required int lastSeen,
      Value<int> hopCount,
      Value<String?> displayName,
      Value<int?> batteryLevel,
      Value<bool> hasInternetAccess,
      Value<String?> metadata,
      Value<int> rowid,
    });
typedef $$NodesTableUpdateCompanionBuilder =
    NodesCompanion Function({
      Value<String> nodeId,
      Value<int> role,
      Value<String?> groupId,
      Value<int> lastSeen,
      Value<int> hopCount,
      Value<String?> displayName,
      Value<int?> batteryLevel,
      Value<bool> hasInternetAccess,
      Value<String?> metadata,
      Value<int> rowid,
    });

class $$NodesTableFilterComposer
    extends Composer<_$AirpassDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batteryLevel => $composableBuilder(
    column: $table.batteryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasInternetAccess => $composableBuilder(
    column: $table.hasInternetAccess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NodesTableOrderingComposer
    extends Composer<_$AirpassDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batteryLevel => $composableBuilder(
    column: $table.batteryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasInternetAccess => $composableBuilder(
    column: $table.hasInternetAccess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodesTableAnnotationComposer
    extends Composer<_$AirpassDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<int> get hopCount =>
      $composableBuilder(column: $table.hopCount, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get batteryLevel => $composableBuilder(
    column: $table.batteryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasInternetAccess => $composableBuilder(
    column: $table.hasInternetAccess,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$AirpassDatabase,
          $NodesTable,
          Node,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (Node, BaseReferences<_$AirpassDatabase, $NodesTable, Node>),
          Node,
          PrefetchHooks Function()
        > {
  $$NodesTableTableManager(_$AirpassDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeId = const Value.absent(),
                Value<int> role = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> lastSeen = const Value.absent(),
                Value<int> hopCount = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<int?> batteryLevel = const Value.absent(),
                Value<bool> hasInternetAccess = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion(
                nodeId: nodeId,
                role: role,
                groupId: groupId,
                lastSeen: lastSeen,
                hopCount: hopCount,
                displayName: displayName,
                batteryLevel: batteryLevel,
                hasInternetAccess: hasInternetAccess,
                metadata: metadata,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeId,
                Value<int> role = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                required int lastSeen,
                Value<int> hopCount = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<int?> batteryLevel = const Value.absent(),
                Value<bool> hasInternetAccess = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion.insert(
                nodeId: nodeId,
                role: role,
                groupId: groupId,
                lastSeen: lastSeen,
                hopCount: hopCount,
                displayName: displayName,
                batteryLevel: batteryLevel,
                hasInternetAccess: hasInternetAccess,
                metadata: metadata,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AirpassDatabase,
      $NodesTable,
      Node,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (Node, BaseReferences<_$AirpassDatabase, $NodesTable, Node>),
      Node,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String messageId,
      required String senderId,
      required String targetId,
      required Uint8List payload,
      Value<int> status,
      required int createdAt,
      required int ttl,
      Value<String?> signature,
      Value<int> mediaType,
      Value<String?> mediaFileName,
      Value<String?> mediaMimeType,
      Value<int?> mediaFileSize,
      Value<String?> mediaHash,
      Value<String?> mediaLocalPath,
      Value<int> mediaAvailability,
      Value<Uint8List?> mediaThumbnail,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> messageId,
      Value<String> senderId,
      Value<String> targetId,
      Value<Uint8List> payload,
      Value<int> status,
      Value<int> createdAt,
      Value<int> ttl,
      Value<String?> signature,
      Value<int> mediaType,
      Value<String?> mediaFileName,
      Value<String?> mediaMimeType,
      Value<int?> mediaFileSize,
      Value<String?> mediaHash,
      Value<String?> mediaLocalPath,
      Value<int> mediaAvailability,
      Value<Uint8List?> mediaThumbnail,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AirpassDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ttl => $composableBuilder(
    column: $table.ttl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaFileName => $composableBuilder(
    column: $table.mediaFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaMimeType => $composableBuilder(
    column: $table.mediaMimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaFileSize => $composableBuilder(
    column: $table.mediaFileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaHash => $composableBuilder(
    column: $table.mediaHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaAvailability => $composableBuilder(
    column: $table.mediaAvailability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get mediaThumbnail => $composableBuilder(
    column: $table.mediaThumbnail,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AirpassDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ttl => $composableBuilder(
    column: $table.ttl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaFileName => $composableBuilder(
    column: $table.mediaFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaMimeType => $composableBuilder(
    column: $table.mediaMimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaFileSize => $composableBuilder(
    column: $table.mediaFileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaHash => $composableBuilder(
    column: $table.mediaHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaAvailability => $composableBuilder(
    column: $table.mediaAvailability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get mediaThumbnail => $composableBuilder(
    column: $table.mediaThumbnail,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AirpassDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get ttl =>
      $composableBuilder(column: $table.ttl, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<int> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get mediaFileName => $composableBuilder(
    column: $table.mediaFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaMimeType => $composableBuilder(
    column: $table.mediaMimeType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaFileSize => $composableBuilder(
    column: $table.mediaFileSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaHash =>
      $composableBuilder(column: $table.mediaHash, builder: (column) => column);

  GeneratedColumn<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaAvailability => $composableBuilder(
    column: $table.mediaAvailability,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get mediaThumbnail => $composableBuilder(
    column: $table.mediaThumbnail,
    builder: (column) => column,
  );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AirpassDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AirpassDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AirpassDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> ttl = const Value.absent(),
                Value<String?> signature = const Value.absent(),
                Value<int> mediaType = const Value.absent(),
                Value<String?> mediaFileName = const Value.absent(),
                Value<String?> mediaMimeType = const Value.absent(),
                Value<int?> mediaFileSize = const Value.absent(),
                Value<String?> mediaHash = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<int> mediaAvailability = const Value.absent(),
                Value<Uint8List?> mediaThumbnail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                messageId: messageId,
                senderId: senderId,
                targetId: targetId,
                payload: payload,
                status: status,
                createdAt: createdAt,
                ttl: ttl,
                signature: signature,
                mediaType: mediaType,
                mediaFileName: mediaFileName,
                mediaMimeType: mediaMimeType,
                mediaFileSize: mediaFileSize,
                mediaHash: mediaHash,
                mediaLocalPath: mediaLocalPath,
                mediaAvailability: mediaAvailability,
                mediaThumbnail: mediaThumbnail,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String senderId,
                required String targetId,
                required Uint8List payload,
                Value<int> status = const Value.absent(),
                required int createdAt,
                required int ttl,
                Value<String?> signature = const Value.absent(),
                Value<int> mediaType = const Value.absent(),
                Value<String?> mediaFileName = const Value.absent(),
                Value<String?> mediaMimeType = const Value.absent(),
                Value<int?> mediaFileSize = const Value.absent(),
                Value<String?> mediaHash = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<int> mediaAvailability = const Value.absent(),
                Value<Uint8List?> mediaThumbnail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                messageId: messageId,
                senderId: senderId,
                targetId: targetId,
                payload: payload,
                status: status,
                createdAt: createdAt,
                ttl: ttl,
                signature: signature,
                mediaType: mediaType,
                mediaFileName: mediaFileName,
                mediaMimeType: mediaMimeType,
                mediaFileSize: mediaFileSize,
                mediaHash: mediaHash,
                mediaLocalPath: mediaLocalPath,
                mediaAvailability: mediaAvailability,
                mediaThumbnail: mediaThumbnail,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AirpassDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AirpassDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      required String groupId,
      required String displayName,
      required int discoveredAt,
      required int lastSeenAt,
      Value<int> memberCount,
      Value<bool> isSubscribed,
      Value<String?> metadata,
      Value<int> rowid,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<String> groupId,
      Value<String> displayName,
      Value<int> discoveredAt,
      Value<int> lastSeenAt,
      Value<int> memberCount,
      Value<bool> isSubscribed,
      Value<String?> metadata,
      Value<int> rowid,
    });

class $$GroupsTableFilterComposer
    extends Composer<_$AirpassDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AirpassDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AirpassDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AirpassDatabase,
          $GroupsTable,
          Group,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (Group, BaseReferences<_$AirpassDatabase, $GroupsTable, Group>),
          Group,
          PrefetchHooks Function()
        > {
  $$GroupsTableTableManager(_$AirpassDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> discoveredAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<bool> isSubscribed = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion(
                groupId: groupId,
                displayName: displayName,
                discoveredAt: discoveredAt,
                lastSeenAt: lastSeenAt,
                memberCount: memberCount,
                isSubscribed: isSubscribed,
                metadata: metadata,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String displayName,
                required int discoveredAt,
                required int lastSeenAt,
                Value<int> memberCount = const Value.absent(),
                Value<bool> isSubscribed = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion.insert(
                groupId: groupId,
                displayName: displayName,
                discoveredAt: discoveredAt,
                lastSeenAt: lastSeenAt,
                memberCount: memberCount,
                isSubscribed: isSubscribed,
                metadata: metadata,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AirpassDatabase,
      $GroupsTable,
      Group,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (Group, BaseReferences<_$AirpassDatabase, $GroupsTable, Group>),
      Group,
      PrefetchHooks Function()
    >;
typedef $$MessageDeliveriesTableCreateCompanionBuilder =
    MessageDeliveriesCompanion Function({
      required String messageId,
      required String peerNodeId,
      required int deliveredAt,
      Value<int> rowid,
    });
typedef $$MessageDeliveriesTableUpdateCompanionBuilder =
    MessageDeliveriesCompanion Function({
      Value<String> messageId,
      Value<String> peerNodeId,
      Value<int> deliveredAt,
      Value<int> rowid,
    });

class $$MessageDeliveriesTableFilterComposer
    extends Composer<_$AirpassDatabase, $MessageDeliveriesTable> {
  $$MessageDeliveriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerNodeId => $composableBuilder(
    column: $table.peerNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageDeliveriesTableOrderingComposer
    extends Composer<_$AirpassDatabase, $MessageDeliveriesTable> {
  $$MessageDeliveriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerNodeId => $composableBuilder(
    column: $table.peerNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageDeliveriesTableAnnotationComposer
    extends Composer<_$AirpassDatabase, $MessageDeliveriesTable> {
  $$MessageDeliveriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get peerNodeId => $composableBuilder(
    column: $table.peerNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => column,
  );
}

class $$MessageDeliveriesTableTableManager
    extends
        RootTableManager<
          _$AirpassDatabase,
          $MessageDeliveriesTable,
          MessageDelivery,
          $$MessageDeliveriesTableFilterComposer,
          $$MessageDeliveriesTableOrderingComposer,
          $$MessageDeliveriesTableAnnotationComposer,
          $$MessageDeliveriesTableCreateCompanionBuilder,
          $$MessageDeliveriesTableUpdateCompanionBuilder,
          (
            MessageDelivery,
            BaseReferences<
              _$AirpassDatabase,
              $MessageDeliveriesTable,
              MessageDelivery
            >,
          ),
          MessageDelivery,
          PrefetchHooks Function()
        > {
  $$MessageDeliveriesTableTableManager(
    _$AirpassDatabase db,
    $MessageDeliveriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageDeliveriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageDeliveriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageDeliveriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> peerNodeId = const Value.absent(),
                Value<int> deliveredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageDeliveriesCompanion(
                messageId: messageId,
                peerNodeId: peerNodeId,
                deliveredAt: deliveredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String peerNodeId,
                required int deliveredAt,
                Value<int> rowid = const Value.absent(),
              }) => MessageDeliveriesCompanion.insert(
                messageId: messageId,
                peerNodeId: peerNodeId,
                deliveredAt: deliveredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageDeliveriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AirpassDatabase,
      $MessageDeliveriesTable,
      MessageDelivery,
      $$MessageDeliveriesTableFilterComposer,
      $$MessageDeliveriesTableOrderingComposer,
      $$MessageDeliveriesTableAnnotationComposer,
      $$MessageDeliveriesTableCreateCompanionBuilder,
      $$MessageDeliveriesTableUpdateCompanionBuilder,
      (
        MessageDelivery,
        BaseReferences<
          _$AirpassDatabase,
          $MessageDeliveriesTable,
          MessageDelivery
        >,
      ),
      MessageDelivery,
      PrefetchHooks Function()
    >;

class $AirpassDatabaseManager {
  final _$AirpassDatabase _db;
  $AirpassDatabaseManager(this._db);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$MessageDeliveriesTableTableManager get messageDeliveries =>
      $$MessageDeliveriesTableTableManager(_db, _db.messageDeliveries);
}
