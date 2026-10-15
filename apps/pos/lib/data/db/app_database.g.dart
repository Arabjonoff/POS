// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalSetting copyWith({String? key, String? value}) =>
      LocalSetting(key: key ?? this.key, value: value ?? this.value);
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoresTable extends Stores with TableInfo<$StoresTable, Store> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptHeaderMeta = const VerificationMeta(
    'receiptHeader',
  );
  @override
  late final GeneratedColumn<String> receiptHeader = GeneratedColumn<String>(
    'receipt_header',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptFooterMeta = const VerificationMeta(
    'receiptFooter',
  );
  @override
  late final GeneratedColumn<String> receiptFooter = GeneratedColumn<String>(
    'receipt_footer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _legalNameMeta = const VerificationMeta(
    'legalName',
  );
  @override
  late final GeneratedColumn<String> legalName = GeneratedColumn<String>(
    'legal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tinMeta = const VerificationMeta('tin');
  @override
  late final GeneratedColumn<String> tin = GeneratedColumn<String>(
    'tin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptLogoMeta = const VerificationMeta(
    'receiptLogo',
  );
  @override
  late final GeneratedColumn<String> receiptLogo = GeneratedColumn<String>(
    'receipt_logo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptOptionsMeta = const VerificationMeta(
    'receiptOptions',
  );
  @override
  late final GeneratedColumn<String> receiptOptions = GeneratedColumn<String>(
    'receipt_options',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    phone,
    receiptHeader,
    receiptFooter,
    legalName,
    tin,
    receiptLogo,
    receiptOptions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<Store> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('receipt_header')) {
      context.handle(
        _receiptHeaderMeta,
        receiptHeader.isAcceptableOrUnknown(
          data['receipt_header']!,
          _receiptHeaderMeta,
        ),
      );
    }
    if (data.containsKey('receipt_footer')) {
      context.handle(
        _receiptFooterMeta,
        receiptFooter.isAcceptableOrUnknown(
          data['receipt_footer']!,
          _receiptFooterMeta,
        ),
      );
    }
    if (data.containsKey('legal_name')) {
      context.handle(
        _legalNameMeta,
        legalName.isAcceptableOrUnknown(data['legal_name']!, _legalNameMeta),
      );
    }
    if (data.containsKey('tin')) {
      context.handle(
        _tinMeta,
        tin.isAcceptableOrUnknown(data['tin']!, _tinMeta),
      );
    }
    if (data.containsKey('receipt_logo')) {
      context.handle(
        _receiptLogoMeta,
        receiptLogo.isAcceptableOrUnknown(
          data['receipt_logo']!,
          _receiptLogoMeta,
        ),
      );
    }
    if (data.containsKey('receipt_options')) {
      context.handle(
        _receiptOptionsMeta,
        receiptOptions.isAcceptableOrUnknown(
          data['receipt_options']!,
          _receiptOptionsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Store map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Store(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      receiptHeader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_header'],
      )!,
      receiptFooter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_footer'],
      )!,
      legalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_name'],
      )!,
      tin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tin'],
      )!,
      receiptLogo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_logo'],
      )!,
      receiptOptions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_options'],
      )!,
    );
  }

  @override
  $StoresTable createAlias(String alias) {
    return $StoresTable(attachedDatabase, alias);
  }
}

class Store extends DataClass implements Insertable<Store> {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String receiptHeader;
  final String receiptFooter;
  final String legalName;

  /// STIR (9 raqam) yoki JShShIR (14 raqam).
  final String tin;

  /// Kulrang PNG (base64), chek kengligiga kichraytirilgan.
  final String receiptLogo;

  /// Ko'rsat/yashir (JSON: `{"show_tin": false, ...}`).
  final String receiptOptions;
  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.receiptHeader,
    required this.receiptFooter,
    required this.legalName,
    required this.tin,
    required this.receiptLogo,
    required this.receiptOptions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['phone'] = Variable<String>(phone);
    map['receipt_header'] = Variable<String>(receiptHeader);
    map['receipt_footer'] = Variable<String>(receiptFooter);
    map['legal_name'] = Variable<String>(legalName);
    map['tin'] = Variable<String>(tin);
    map['receipt_logo'] = Variable<String>(receiptLogo);
    map['receipt_options'] = Variable<String>(receiptOptions);
    return map;
  }

  StoresCompanion toCompanion(bool nullToAbsent) {
    return StoresCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      phone: Value(phone),
      receiptHeader: Value(receiptHeader),
      receiptFooter: Value(receiptFooter),
      legalName: Value(legalName),
      tin: Value(tin),
      receiptLogo: Value(receiptLogo),
      receiptOptions: Value(receiptOptions),
    );
  }

  factory Store.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Store(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      phone: serializer.fromJson<String>(json['phone']),
      receiptHeader: serializer.fromJson<String>(json['receiptHeader']),
      receiptFooter: serializer.fromJson<String>(json['receiptFooter']),
      legalName: serializer.fromJson<String>(json['legalName']),
      tin: serializer.fromJson<String>(json['tin']),
      receiptLogo: serializer.fromJson<String>(json['receiptLogo']),
      receiptOptions: serializer.fromJson<String>(json['receiptOptions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'phone': serializer.toJson<String>(phone),
      'receiptHeader': serializer.toJson<String>(receiptHeader),
      'receiptFooter': serializer.toJson<String>(receiptFooter),
      'legalName': serializer.toJson<String>(legalName),
      'tin': serializer.toJson<String>(tin),
      'receiptLogo': serializer.toJson<String>(receiptLogo),
      'receiptOptions': serializer.toJson<String>(receiptOptions),
    };
  }

  Store copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? receiptHeader,
    String? receiptFooter,
    String? legalName,
    String? tin,
    String? receiptLogo,
    String? receiptOptions,
  }) => Store(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    receiptHeader: receiptHeader ?? this.receiptHeader,
    receiptFooter: receiptFooter ?? this.receiptFooter,
    legalName: legalName ?? this.legalName,
    tin: tin ?? this.tin,
    receiptLogo: receiptLogo ?? this.receiptLogo,
    receiptOptions: receiptOptions ?? this.receiptOptions,
  );
  Store copyWithCompanion(StoresCompanion data) {
    return Store(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      receiptHeader: data.receiptHeader.present
          ? data.receiptHeader.value
          : this.receiptHeader,
      receiptFooter: data.receiptFooter.present
          ? data.receiptFooter.value
          : this.receiptFooter,
      legalName: data.legalName.present ? data.legalName.value : this.legalName,
      tin: data.tin.present ? data.tin.value : this.tin,
      receiptLogo: data.receiptLogo.present
          ? data.receiptLogo.value
          : this.receiptLogo,
      receiptOptions: data.receiptOptions.present
          ? data.receiptOptions.value
          : this.receiptOptions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Store(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('receiptHeader: $receiptHeader, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('legalName: $legalName, ')
          ..write('tin: $tin, ')
          ..write('receiptLogo: $receiptLogo, ')
          ..write('receiptOptions: $receiptOptions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    phone,
    receiptHeader,
    receiptFooter,
    legalName,
    tin,
    receiptLogo,
    receiptOptions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Store &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.receiptHeader == this.receiptHeader &&
          other.receiptFooter == this.receiptFooter &&
          other.legalName == this.legalName &&
          other.tin == this.tin &&
          other.receiptLogo == this.receiptLogo &&
          other.receiptOptions == this.receiptOptions);
}

class StoresCompanion extends UpdateCompanion<Store> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> address;
  final Value<String> phone;
  final Value<String> receiptHeader;
  final Value<String> receiptFooter;
  final Value<String> legalName;
  final Value<String> tin;
  final Value<String> receiptLogo;
  final Value<String> receiptOptions;
  final Value<int> rowid;
  const StoresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.receiptHeader = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    this.legalName = const Value.absent(),
    this.tin = const Value.absent(),
    this.receiptLogo = const Value.absent(),
    this.receiptOptions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoresCompanion.insert({
    required String id,
    required String name,
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.receiptHeader = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    this.legalName = const Value.absent(),
    this.tin = const Value.absent(),
    this.receiptLogo = const Value.absent(),
    this.receiptOptions = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Store> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? receiptHeader,
    Expression<String>? receiptFooter,
    Expression<String>? legalName,
    Expression<String>? tin,
    Expression<String>? receiptLogo,
    Expression<String>? receiptOptions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (receiptHeader != null) 'receipt_header': receiptHeader,
      if (receiptFooter != null) 'receipt_footer': receiptFooter,
      if (legalName != null) 'legal_name': legalName,
      if (tin != null) 'tin': tin,
      if (receiptLogo != null) 'receipt_logo': receiptLogo,
      if (receiptOptions != null) 'receipt_options': receiptOptions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoresCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? address,
    Value<String>? phone,
    Value<String>? receiptHeader,
    Value<String>? receiptFooter,
    Value<String>? legalName,
    Value<String>? tin,
    Value<String>? receiptLogo,
    Value<String>? receiptOptions,
    Value<int>? rowid,
  }) {
    return StoresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      legalName: legalName ?? this.legalName,
      tin: tin ?? this.tin,
      receiptLogo: receiptLogo ?? this.receiptLogo,
      receiptOptions: receiptOptions ?? this.receiptOptions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (receiptHeader.present) {
      map['receipt_header'] = Variable<String>(receiptHeader.value);
    }
    if (receiptFooter.present) {
      map['receipt_footer'] = Variable<String>(receiptFooter.value);
    }
    if (legalName.present) {
      map['legal_name'] = Variable<String>(legalName.value);
    }
    if (tin.present) {
      map['tin'] = Variable<String>(tin.value);
    }
    if (receiptLogo.present) {
      map['receipt_logo'] = Variable<String>(receiptLogo.value);
    }
    if (receiptOptions.present) {
      map['receipt_options'] = Variable<String>(receiptOptions.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('receiptHeader: $receiptHeader, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('legalName: $legalName, ')
          ..write('tin: $tin, ')
          ..write('receiptLogo: $receiptLogo, ')
          ..write('receiptOptions: $receiptOptions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffUsersTable extends StaffUsers
    with TableInfo<$StaffUsersTable, StaffUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    phone,
    fullName,
    role,
    isActive,
    pinHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StaffUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffUser(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      ),
    );
  }

  @override
  $StaffUsersTable createAlias(String alias) {
    return $StaffUsersTable(attachedDatabase, alias);
  }
}

class StaffUser extends DataClass implements Insertable<StaffUser> {
  final String id;
  final String? phone;
  final String fullName;

  /// `owner` / `manager` / `cashier`.
  final String role;
  final bool isActive;
  final String? pinHash;
  const StaffUser({
    required this.id,
    this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.pinHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['full_name'] = Variable<String>(fullName);
    map['role'] = Variable<String>(role);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || pinHash != null) {
      map['pin_hash'] = Variable<String>(pinHash);
    }
    return map;
  }

  StaffUsersCompanion toCompanion(bool nullToAbsent) {
    return StaffUsersCompanion(
      id: Value(id),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      fullName: Value(fullName),
      role: Value(role),
      isActive: Value(isActive),
      pinHash: pinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pinHash),
    );
  }

  factory StaffUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffUser(
      id: serializer.fromJson<String>(json['id']),
      phone: serializer.fromJson<String?>(json['phone']),
      fullName: serializer.fromJson<String>(json['fullName']),
      role: serializer.fromJson<String>(json['role']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      pinHash: serializer.fromJson<String?>(json['pinHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'phone': serializer.toJson<String?>(phone),
      'fullName': serializer.toJson<String>(fullName),
      'role': serializer.toJson<String>(role),
      'isActive': serializer.toJson<bool>(isActive),
      'pinHash': serializer.toJson<String?>(pinHash),
    };
  }

  StaffUser copyWith({
    String? id,
    Value<String?> phone = const Value.absent(),
    String? fullName,
    String? role,
    bool? isActive,
    Value<String?> pinHash = const Value.absent(),
  }) => StaffUser(
    id: id ?? this.id,
    phone: phone.present ? phone.value : this.phone,
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    isActive: isActive ?? this.isActive,
    pinHash: pinHash.present ? pinHash.value : this.pinHash,
  );
  StaffUser copyWithCompanion(StaffUsersCompanion data) {
    return StaffUser(
      id: data.id.present ? data.id.value : this.id,
      phone: data.phone.present ? data.phone.value : this.phone,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      role: data.role.present ? data.role.value : this.role,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffUser(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('pinHash: $pinHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, phone, fullName, role, isActive, pinHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffUser &&
          other.id == this.id &&
          other.phone == this.phone &&
          other.fullName == this.fullName &&
          other.role == this.role &&
          other.isActive == this.isActive &&
          other.pinHash == this.pinHash);
}

class StaffUsersCompanion extends UpdateCompanion<StaffUser> {
  final Value<String> id;
  final Value<String?> phone;
  final Value<String> fullName;
  final Value<String> role;
  final Value<bool> isActive;
  final Value<String?> pinHash;
  final Value<int> rowid;
  const StaffUsersCompanion({
    this.id = const Value.absent(),
    this.phone = const Value.absent(),
    this.fullName = const Value.absent(),
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffUsersCompanion.insert({
    required String id,
    this.phone = const Value.absent(),
    required String fullName,
    required String role,
    this.isActive = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName),
       role = Value(role);
  static Insertable<StaffUser> custom({
    Expression<String>? id,
    Expression<String>? phone,
    Expression<String>? fullName,
    Expression<String>? role,
    Expression<bool>? isActive,
    Expression<String>? pinHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phone != null) 'phone': phone,
      if (fullName != null) 'full_name': fullName,
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
      if (pinHash != null) 'pin_hash': pinHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffUsersCompanion copyWith({
    Value<String>? id,
    Value<String?>? phone,
    Value<String>? fullName,
    Value<String>? role,
    Value<bool>? isActive,
    Value<String?>? pinHash,
    Value<int>? rowid,
  }) {
    return StaffUsersCompanion(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      pinHash: pinHash ?? this.pinHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffUsersCompanion(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('pinHash: $pinHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, Unit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isFractionalMeta = const VerificationMeta(
    'isFractional',
  );
  @override
  late final GeneratedColumn<bool> isFractional = GeneratedColumn<bool>(
    'is_fractional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fractional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    isFractional,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(
    Insertable<Unit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('is_fractional')) {
      context.handle(
        _isFractionalMeta,
        isFractional.isAcceptableOrUnknown(
          data['is_fractional']!,
          _isFractionalMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Unit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Unit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isFractional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fractional'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class Unit extends DataClass implements Insertable<Unit> {
  final String id;

  /// `pcs` / `kg` / `g` / `l` / `m` / `pack` yoki o'z kodi.
  final String code;

  /// Standart birliklarda bo'sh — nom tarjimadan (`UnitCode`).
  final String name;
  final bool isFractional;
  final DateTime? deletedAt;
  const Unit({
    required this.id,
    required this.code,
    required this.name,
    required this.isFractional,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['is_fractional'] = Variable<bool>(isFractional);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      isFractional: Value(isFractional),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Unit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Unit(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      isFractional: serializer.fromJson<bool>(json['isFractional']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'isFractional': serializer.toJson<bool>(isFractional),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Unit copyWith({
    String? id,
    String? code,
    String? name,
    bool? isFractional,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Unit(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    isFractional: isFractional ?? this.isFractional,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Unit copyWithCompanion(UnitsCompanion data) {
    return Unit(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      isFractional: data.isFractional.present
          ? data.isFractional.value
          : this.isFractional,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Unit(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('isFractional: $isFractional, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, isFractional, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Unit &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.isFractional == this.isFractional &&
          other.deletedAt == this.deletedAt);
}

class UnitsCompanion extends UpdateCompanion<Unit> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<bool> isFractional;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.isFractional = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsCompanion.insert({
    required String id,
    required String code,
    this.name = const Value.absent(),
    this.isFractional = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code);
  static Insertable<Unit> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? isFractional,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (isFractional != null) 'is_fractional': isFractional,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<bool>? isFractional,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return UnitsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isFractional: isFractional ?? this.isFractional,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isFractional.present) {
      map['is_fractional'] = Variable<bool>(isFractional.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('isFractional: $isFractional, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    parentId,
    sort,
    color,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String? parentId;
  final int sort;

  /// Dizayn palitrasi kaliti (masalan, `green`).
  final String? color;
  final DateTime? deletedAt;
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.sort,
    this.color,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['sort'] = Variable<int>(sort);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      sort: Value(sort),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      sort: serializer.fromJson<int>(json['sort']),
      color: serializer.fromJson<String?>(json['color']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'sort': serializer.toJson<int>(sort),
      'color': serializer.toJson<String?>(color),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    int? sort,
    Value<String?> color = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    sort: sort ?? this.sort,
    color: color.present ? color.value : this.color,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      sort: data.sort.present ? data.sort.value : this.sort,
      color: data.color.present ? data.color.value : this.color,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('sort: $sort, ')
          ..write('color: $color, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId, sort, color, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.sort == this.sort &&
          other.color == this.color &&
          other.deletedAt == this.deletedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int> sort;
  final Value<String?> color;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sort = const Value.absent(),
    this.color = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.sort = const Value.absent(),
    this.color = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<int>? sort,
    Expression<String>? color,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (sort != null) 'sort': sort,
      if (color != null) 'color': color,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<int>? sort,
    Value<String?>? color,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      sort: sort ?? this.sort,
      color: color ?? this.color,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('sort: $sort, ')
          ..write('color: $color, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchKeyMeta = const VerificationMeta(
    'searchKey',
  );
  @override
  late final GeneratedColumn<String> searchKey = GeneratedColumn<String>(
    'search_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellPriceTiyinMeta = const VerificationMeta(
    'sellPriceTiyin',
  );
  @override
  late final GeneratedColumn<int> sellPriceTiyin = GeneratedColumn<int>(
    'sell_price_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceTiyinMeta = const VerificationMeta(
    'costPriceTiyin',
  );
  @override
  late final GeneratedColumn<int> costPriceTiyin = GeneratedColumn<int>(
    'cost_price_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isWeightedMeta = const VerificationMeta(
    'isWeighted',
  );
  @override
  late final GeneratedColumn<bool> isWeighted = GeneratedColumn<bool>(
    'is_weighted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_weighted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pluCodeMeta = const VerificationMeta(
    'pluCode',
  );
  @override
  late final GeneratedColumn<String> pluCode = GeneratedColumn<String>(
    'plu_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minStockMilliMeta = const VerificationMeta(
    'minStockMilli',
  );
  @override
  late final GeneratedColumn<int> minStockMilli = GeneratedColumn<int>(
    'min_stock_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ikpuCodeMeta = const VerificationMeta(
    'ikpuCode',
  );
  @override
  late final GeneratedColumn<String> ikpuCode = GeneratedColumn<String>(
    'ikpu_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quickButtonMeta = const VerificationMeta(
    'quickButton',
  );
  @override
  late final GeneratedColumn<bool> quickButton = GeneratedColumn<bool>(
    'quick_button',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quick_button" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageIdMeta = const VerificationMeta(
    'imageId',
  );
  @override
  late final GeneratedColumn<String> imageId = GeneratedColumn<String>(
    'image_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    searchKey,
    categoryId,
    unitId,
    sellPriceTiyin,
    costPriceTiyin,
    isWeighted,
    pluCode,
    minStockMilli,
    ikpuCode,
    quickButton,
    isActive,
    updatedAt,
    deletedAt,
    imageId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('search_key')) {
      context.handle(
        _searchKeyMeta,
        searchKey.isAcceptableOrUnknown(data['search_key']!, _searchKeyMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('sell_price_tiyin')) {
      context.handle(
        _sellPriceTiyinMeta,
        sellPriceTiyin.isAcceptableOrUnknown(
          data['sell_price_tiyin']!,
          _sellPriceTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellPriceTiyinMeta);
    }
    if (data.containsKey('cost_price_tiyin')) {
      context.handle(
        _costPriceTiyinMeta,
        costPriceTiyin.isAcceptableOrUnknown(
          data['cost_price_tiyin']!,
          _costPriceTiyinMeta,
        ),
      );
    }
    if (data.containsKey('is_weighted')) {
      context.handle(
        _isWeightedMeta,
        isWeighted.isAcceptableOrUnknown(data['is_weighted']!, _isWeightedMeta),
      );
    }
    if (data.containsKey('plu_code')) {
      context.handle(
        _pluCodeMeta,
        pluCode.isAcceptableOrUnknown(data['plu_code']!, _pluCodeMeta),
      );
    }
    if (data.containsKey('min_stock_milli')) {
      context.handle(
        _minStockMilliMeta,
        minStockMilli.isAcceptableOrUnknown(
          data['min_stock_milli']!,
          _minStockMilliMeta,
        ),
      );
    }
    if (data.containsKey('ikpu_code')) {
      context.handle(
        _ikpuCodeMeta,
        ikpuCode.isAcceptableOrUnknown(data['ikpu_code']!, _ikpuCodeMeta),
      );
    }
    if (data.containsKey('quick_button')) {
      context.handle(
        _quickButtonMeta,
        quickButton.isAcceptableOrUnknown(
          data['quick_button']!,
          _quickButtonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('image_id')) {
      context.handle(
        _imageIdMeta,
        imageId.isAcceptableOrUnknown(data['image_id']!, _imageIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      searchKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_key'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      )!,
      sellPriceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sell_price_tiyin'],
      )!,
      costPriceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_price_tiyin'],
      )!,
      isWeighted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_weighted'],
      )!,
      pluCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plu_code'],
      ),
      minStockMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_stock_milli'],
      )!,
      ikpuCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ikpu_code'],
      ),
      quickButton: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quick_button'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      imageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_id'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String name;

  /// Qidiruv kaliti: kichik harf, lotin/kirill transliteratsiyasi (T-042).
  final String searchKey;
  final String? categoryId;
  final String unitId;
  final int sellPriceTiyin;
  final int costPriceTiyin;
  final bool isWeighted;

  /// Vaznli tovar uchun tarozi kodi (5 raqam).
  final String? pluCode;
  final int minStockMilli;
  final String? ikpuCode;
  final bool quickButton;
  final bool isActive;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Joriy rasm (T-105): fayl — ilova papkasida `<imageId>.jpg`.
  final String? imageId;
  const Product({
    required this.id,
    required this.name,
    required this.searchKey,
    this.categoryId,
    required this.unitId,
    required this.sellPriceTiyin,
    required this.costPriceTiyin,
    required this.isWeighted,
    this.pluCode,
    required this.minStockMilli,
    this.ikpuCode,
    required this.quickButton,
    required this.isActive,
    this.updatedAt,
    this.deletedAt,
    this.imageId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['search_key'] = Variable<String>(searchKey);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['unit_id'] = Variable<String>(unitId);
    map['sell_price_tiyin'] = Variable<int>(sellPriceTiyin);
    map['cost_price_tiyin'] = Variable<int>(costPriceTiyin);
    map['is_weighted'] = Variable<bool>(isWeighted);
    if (!nullToAbsent || pluCode != null) {
      map['plu_code'] = Variable<String>(pluCode);
    }
    map['min_stock_milli'] = Variable<int>(minStockMilli);
    if (!nullToAbsent || ikpuCode != null) {
      map['ikpu_code'] = Variable<String>(ikpuCode);
    }
    map['quick_button'] = Variable<bool>(quickButton);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || imageId != null) {
      map['image_id'] = Variable<String>(imageId);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      searchKey: Value(searchKey),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      unitId: Value(unitId),
      sellPriceTiyin: Value(sellPriceTiyin),
      costPriceTiyin: Value(costPriceTiyin),
      isWeighted: Value(isWeighted),
      pluCode: pluCode == null && nullToAbsent
          ? const Value.absent()
          : Value(pluCode),
      minStockMilli: Value(minStockMilli),
      ikpuCode: ikpuCode == null && nullToAbsent
          ? const Value.absent()
          : Value(ikpuCode),
      quickButton: Value(quickButton),
      isActive: Value(isActive),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      imageId: imageId == null && nullToAbsent
          ? const Value.absent()
          : Value(imageId),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      searchKey: serializer.fromJson<String>(json['searchKey']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      unitId: serializer.fromJson<String>(json['unitId']),
      sellPriceTiyin: serializer.fromJson<int>(json['sellPriceTiyin']),
      costPriceTiyin: serializer.fromJson<int>(json['costPriceTiyin']),
      isWeighted: serializer.fromJson<bool>(json['isWeighted']),
      pluCode: serializer.fromJson<String?>(json['pluCode']),
      minStockMilli: serializer.fromJson<int>(json['minStockMilli']),
      ikpuCode: serializer.fromJson<String?>(json['ikpuCode']),
      quickButton: serializer.fromJson<bool>(json['quickButton']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      imageId: serializer.fromJson<String?>(json['imageId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'searchKey': serializer.toJson<String>(searchKey),
      'categoryId': serializer.toJson<String?>(categoryId),
      'unitId': serializer.toJson<String>(unitId),
      'sellPriceTiyin': serializer.toJson<int>(sellPriceTiyin),
      'costPriceTiyin': serializer.toJson<int>(costPriceTiyin),
      'isWeighted': serializer.toJson<bool>(isWeighted),
      'pluCode': serializer.toJson<String?>(pluCode),
      'minStockMilli': serializer.toJson<int>(minStockMilli),
      'ikpuCode': serializer.toJson<String?>(ikpuCode),
      'quickButton': serializer.toJson<bool>(quickButton),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'imageId': serializer.toJson<String?>(imageId),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? searchKey,
    Value<String?> categoryId = const Value.absent(),
    String? unitId,
    int? sellPriceTiyin,
    int? costPriceTiyin,
    bool? isWeighted,
    Value<String?> pluCode = const Value.absent(),
    int? minStockMilli,
    Value<String?> ikpuCode = const Value.absent(),
    bool? quickButton,
    bool? isActive,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> imageId = const Value.absent(),
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    searchKey: searchKey ?? this.searchKey,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    unitId: unitId ?? this.unitId,
    sellPriceTiyin: sellPriceTiyin ?? this.sellPriceTiyin,
    costPriceTiyin: costPriceTiyin ?? this.costPriceTiyin,
    isWeighted: isWeighted ?? this.isWeighted,
    pluCode: pluCode.present ? pluCode.value : this.pluCode,
    minStockMilli: minStockMilli ?? this.minStockMilli,
    ikpuCode: ikpuCode.present ? ikpuCode.value : this.ikpuCode,
    quickButton: quickButton ?? this.quickButton,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    imageId: imageId.present ? imageId.value : this.imageId,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      searchKey: data.searchKey.present ? data.searchKey.value : this.searchKey,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      sellPriceTiyin: data.sellPriceTiyin.present
          ? data.sellPriceTiyin.value
          : this.sellPriceTiyin,
      costPriceTiyin: data.costPriceTiyin.present
          ? data.costPriceTiyin.value
          : this.costPriceTiyin,
      isWeighted: data.isWeighted.present
          ? data.isWeighted.value
          : this.isWeighted,
      pluCode: data.pluCode.present ? data.pluCode.value : this.pluCode,
      minStockMilli: data.minStockMilli.present
          ? data.minStockMilli.value
          : this.minStockMilli,
      ikpuCode: data.ikpuCode.present ? data.ikpuCode.value : this.ikpuCode,
      quickButton: data.quickButton.present
          ? data.quickButton.value
          : this.quickButton,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      imageId: data.imageId.present ? data.imageId.value : this.imageId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('searchKey: $searchKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('unitId: $unitId, ')
          ..write('sellPriceTiyin: $sellPriceTiyin, ')
          ..write('costPriceTiyin: $costPriceTiyin, ')
          ..write('isWeighted: $isWeighted, ')
          ..write('pluCode: $pluCode, ')
          ..write('minStockMilli: $minStockMilli, ')
          ..write('ikpuCode: $ikpuCode, ')
          ..write('quickButton: $quickButton, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('imageId: $imageId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    searchKey,
    categoryId,
    unitId,
    sellPriceTiyin,
    costPriceTiyin,
    isWeighted,
    pluCode,
    minStockMilli,
    ikpuCode,
    quickButton,
    isActive,
    updatedAt,
    deletedAt,
    imageId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.searchKey == this.searchKey &&
          other.categoryId == this.categoryId &&
          other.unitId == this.unitId &&
          other.sellPriceTiyin == this.sellPriceTiyin &&
          other.costPriceTiyin == this.costPriceTiyin &&
          other.isWeighted == this.isWeighted &&
          other.pluCode == this.pluCode &&
          other.minStockMilli == this.minStockMilli &&
          other.ikpuCode == this.ikpuCode &&
          other.quickButton == this.quickButton &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.imageId == this.imageId);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> searchKey;
  final Value<String?> categoryId;
  final Value<String> unitId;
  final Value<int> sellPriceTiyin;
  final Value<int> costPriceTiyin;
  final Value<bool> isWeighted;
  final Value<String?> pluCode;
  final Value<int> minStockMilli;
  final Value<String?> ikpuCode;
  final Value<bool> quickButton;
  final Value<bool> isActive;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> imageId;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.searchKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.sellPriceTiyin = const Value.absent(),
    this.costPriceTiyin = const Value.absent(),
    this.isWeighted = const Value.absent(),
    this.pluCode = const Value.absent(),
    this.minStockMilli = const Value.absent(),
    this.ikpuCode = const Value.absent(),
    this.quickButton = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.imageId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.searchKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    required String unitId,
    required int sellPriceTiyin,
    this.costPriceTiyin = const Value.absent(),
    this.isWeighted = const Value.absent(),
    this.pluCode = const Value.absent(),
    this.minStockMilli = const Value.absent(),
    this.ikpuCode = const Value.absent(),
    this.quickButton = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.imageId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       unitId = Value(unitId),
       sellPriceTiyin = Value(sellPriceTiyin);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? searchKey,
    Expression<String>? categoryId,
    Expression<String>? unitId,
    Expression<int>? sellPriceTiyin,
    Expression<int>? costPriceTiyin,
    Expression<bool>? isWeighted,
    Expression<String>? pluCode,
    Expression<int>? minStockMilli,
    Expression<String>? ikpuCode,
    Expression<bool>? quickButton,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? imageId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (searchKey != null) 'search_key': searchKey,
      if (categoryId != null) 'category_id': categoryId,
      if (unitId != null) 'unit_id': unitId,
      if (sellPriceTiyin != null) 'sell_price_tiyin': sellPriceTiyin,
      if (costPriceTiyin != null) 'cost_price_tiyin': costPriceTiyin,
      if (isWeighted != null) 'is_weighted': isWeighted,
      if (pluCode != null) 'plu_code': pluCode,
      if (minStockMilli != null) 'min_stock_milli': minStockMilli,
      if (ikpuCode != null) 'ikpu_code': ikpuCode,
      if (quickButton != null) 'quick_button': quickButton,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (imageId != null) 'image_id': imageId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? searchKey,
    Value<String?>? categoryId,
    Value<String>? unitId,
    Value<int>? sellPriceTiyin,
    Value<int>? costPriceTiyin,
    Value<bool>? isWeighted,
    Value<String?>? pluCode,
    Value<int>? minStockMilli,
    Value<String?>? ikpuCode,
    Value<bool>? quickButton,
    Value<bool>? isActive,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? imageId,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      searchKey: searchKey ?? this.searchKey,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      sellPriceTiyin: sellPriceTiyin ?? this.sellPriceTiyin,
      costPriceTiyin: costPriceTiyin ?? this.costPriceTiyin,
      isWeighted: isWeighted ?? this.isWeighted,
      pluCode: pluCode ?? this.pluCode,
      minStockMilli: minStockMilli ?? this.minStockMilli,
      ikpuCode: ikpuCode ?? this.ikpuCode,
      quickButton: quickButton ?? this.quickButton,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      imageId: imageId ?? this.imageId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (searchKey.present) {
      map['search_key'] = Variable<String>(searchKey.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (sellPriceTiyin.present) {
      map['sell_price_tiyin'] = Variable<int>(sellPriceTiyin.value);
    }
    if (costPriceTiyin.present) {
      map['cost_price_tiyin'] = Variable<int>(costPriceTiyin.value);
    }
    if (isWeighted.present) {
      map['is_weighted'] = Variable<bool>(isWeighted.value);
    }
    if (pluCode.present) {
      map['plu_code'] = Variable<String>(pluCode.value);
    }
    if (minStockMilli.present) {
      map['min_stock_milli'] = Variable<int>(minStockMilli.value);
    }
    if (ikpuCode.present) {
      map['ikpu_code'] = Variable<String>(ikpuCode.value);
    }
    if (quickButton.present) {
      map['quick_button'] = Variable<bool>(quickButton.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (imageId.present) {
      map['image_id'] = Variable<String>(imageId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('searchKey: $searchKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('unitId: $unitId, ')
          ..write('sellPriceTiyin: $sellPriceTiyin, ')
          ..write('costPriceTiyin: $costPriceTiyin, ')
          ..write('isWeighted: $isWeighted, ')
          ..write('pluCode: $pluCode, ')
          ..write('minStockMilli: $minStockMilli, ')
          ..write('ikpuCode: $ikpuCode, ')
          ..write('quickButton: $quickButton, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('imageId: $imageId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductBarcodesTable extends ProductBarcodes
    with TableInfo<$ProductBarcodesTable, ProductBarcode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductBarcodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [barcode, productId, isPrimary];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_barcodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductBarcode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {barcode};
  @override
  ProductBarcode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductBarcode(
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
    );
  }

  @override
  $ProductBarcodesTable createAlias(String alias) {
    return $ProductBarcodesTable(attachedDatabase, alias);
  }
}

class ProductBarcode extends DataClass implements Insertable<ProductBarcode> {
  /// Matn (boshidagi nollar saqlanadi), tenant ichida yagona.
  final String barcode;
  final String productId;
  final bool isPrimary;
  const ProductBarcode({
    required this.barcode,
    required this.productId,
    required this.isPrimary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['barcode'] = Variable<String>(barcode);
    map['product_id'] = Variable<String>(productId);
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  ProductBarcodesCompanion toCompanion(bool nullToAbsent) {
    return ProductBarcodesCompanion(
      barcode: Value(barcode),
      productId: Value(productId),
      isPrimary: Value(isPrimary),
    );
  }

  factory ProductBarcode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductBarcode(
      barcode: serializer.fromJson<String>(json['barcode']),
      productId: serializer.fromJson<String>(json['productId']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'barcode': serializer.toJson<String>(barcode),
      'productId': serializer.toJson<String>(productId),
      'isPrimary': serializer.toJson<bool>(isPrimary),
    };
  }

  ProductBarcode copyWith({
    String? barcode,
    String? productId,
    bool? isPrimary,
  }) => ProductBarcode(
    barcode: barcode ?? this.barcode,
    productId: productId ?? this.productId,
    isPrimary: isPrimary ?? this.isPrimary,
  );
  ProductBarcode copyWithCompanion(ProductBarcodesCompanion data) {
    return ProductBarcode(
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      productId: data.productId.present ? data.productId.value : this.productId,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductBarcode(')
          ..write('barcode: $barcode, ')
          ..write('productId: $productId, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(barcode, productId, isPrimary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductBarcode &&
          other.barcode == this.barcode &&
          other.productId == this.productId &&
          other.isPrimary == this.isPrimary);
}

class ProductBarcodesCompanion extends UpdateCompanion<ProductBarcode> {
  final Value<String> barcode;
  final Value<String> productId;
  final Value<bool> isPrimary;
  final Value<int> rowid;
  const ProductBarcodesCompanion({
    this.barcode = const Value.absent(),
    this.productId = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductBarcodesCompanion.insert({
    required String barcode,
    required String productId,
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : barcode = Value(barcode),
       productId = Value(productId);
  static Insertable<ProductBarcode> custom({
    Expression<String>? barcode,
    Expression<String>? productId,
    Expression<bool>? isPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (barcode != null) 'barcode': barcode,
      if (productId != null) 'product_id': productId,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductBarcodesCompanion copyWith({
    Value<String>? barcode,
    Value<String>? productId,
    Value<bool>? isPrimary,
    Value<int>? rowid,
  }) {
    return ProductBarcodesCompanion(
      barcode: barcode ?? this.barcode,
      productId: productId ?? this.productId,
      isPrimary: isPrimary ?? this.isPrimary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductBarcodesCompanion(')
          ..write('barcode: $barcode, ')
          ..write('productId: $productId, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _debtLimitTiyinMeta = const VerificationMeta(
    'debtLimitTiyin',
  );
  @override
  late final GeneratedColumn<int> debtLimitTiyin = GeneratedColumn<int>(
    'debt_limit_tiyin',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceTiyinMeta = const VerificationMeta(
    'balanceTiyin',
  );
  @override
  late final GeneratedColumn<int> balanceTiyin = GeneratedColumn<int>(
    'balance_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fullName,
    phone,
    note,
    debtLimitTiyin,
    balanceTiyin,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Customer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('debt_limit_tiyin')) {
      context.handle(
        _debtLimitTiyinMeta,
        debtLimitTiyin.isAcceptableOrUnknown(
          data['debt_limit_tiyin']!,
          _debtLimitTiyinMeta,
        ),
      );
    }
    if (data.containsKey('balance_tiyin')) {
      context.handle(
        _balanceTiyinMeta,
        balanceTiyin.isAcceptableOrUnknown(
          data['balance_tiyin']!,
          _balanceTiyinMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      debtLimitTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}debt_limit_tiyin'],
      ),
      balanceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_tiyin'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final String id;
  final String fullName;
  final String phone;
  final String note;

  /// `null` — cheklovsiz.
  final int? debtLimitTiyin;

  /// Serverdagi qarz (pull paytidagi holat); lokal yozuvlar alohida qo'shiladi.
  final int balanceTiyin;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.note,
    this.debtLimitTiyin,
    required this.balanceTiyin,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['phone'] = Variable<String>(phone);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || debtLimitTiyin != null) {
      map['debt_limit_tiyin'] = Variable<int>(debtLimitTiyin);
    }
    map['balance_tiyin'] = Variable<int>(balanceTiyin);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      fullName: Value(fullName),
      phone: Value(phone),
      note: Value(note),
      debtLimitTiyin: debtLimitTiyin == null && nullToAbsent
          ? const Value.absent()
          : Value(debtLimitTiyin),
      balanceTiyin: Value(balanceTiyin),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Customer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phone: serializer.fromJson<String>(json['phone']),
      note: serializer.fromJson<String>(json['note']),
      debtLimitTiyin: serializer.fromJson<int?>(json['debtLimitTiyin']),
      balanceTiyin: serializer.fromJson<int>(json['balanceTiyin']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'phone': serializer.toJson<String>(phone),
      'note': serializer.toJson<String>(note),
      'debtLimitTiyin': serializer.toJson<int?>(debtLimitTiyin),
      'balanceTiyin': serializer.toJson<int>(balanceTiyin),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Customer copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? note,
    Value<int?> debtLimitTiyin = const Value.absent(),
    int? balanceTiyin,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Customer(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    note: note ?? this.note,
    debtLimitTiyin: debtLimitTiyin.present
        ? debtLimitTiyin.value
        : this.debtLimitTiyin,
    balanceTiyin: balanceTiyin ?? this.balanceTiyin,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phone: data.phone.present ? data.phone.value : this.phone,
      note: data.note.present ? data.note.value : this.note,
      debtLimitTiyin: data.debtLimitTiyin.present
          ? data.debtLimitTiyin.value
          : this.debtLimitTiyin,
      balanceTiyin: data.balanceTiyin.present
          ? data.balanceTiyin.value
          : this.balanceTiyin,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('debtLimitTiyin: $debtLimitTiyin, ')
          ..write('balanceTiyin: $balanceTiyin, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    phone,
    note,
    debtLimitTiyin,
    balanceTiyin,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.phone == this.phone &&
          other.note == this.note &&
          other.debtLimitTiyin == this.debtLimitTiyin &&
          other.balanceTiyin == this.balanceTiyin &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> phone;
  final Value<String> note;
  final Value<int?> debtLimitTiyin;
  final Value<int> balanceTiyin;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.debtLimitTiyin = const Value.absent(),
    this.balanceTiyin = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String fullName,
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.debtLimitTiyin = const Value.absent(),
    this.balanceTiyin = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? phone,
    Expression<String>? note,
    Expression<int>? debtLimitTiyin,
    Expression<int>? balanceTiyin,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (debtLimitTiyin != null) 'debt_limit_tiyin': debtLimitTiyin,
      if (balanceTiyin != null) 'balance_tiyin': balanceTiyin,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String>? phone,
    Value<String>? note,
    Value<int?>? debtLimitTiyin,
    Value<int>? balanceTiyin,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      debtLimitTiyin: debtLimitTiyin ?? this.debtLimitTiyin,
      balanceTiyin: balanceTiyin ?? this.balanceTiyin,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (debtLimitTiyin.present) {
      map['debt_limit_tiyin'] = Variable<int>(debtLimitTiyin.value);
    }
    if (balanceTiyin.present) {
      map['balance_tiyin'] = Variable<int>(balanceTiyin.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('debtLimitTiyin: $debtLimitTiyin, ')
          ..write('balanceTiyin: $balanceTiyin, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SuppliersTable extends Suppliers
    with TableInfo<$SuppliersTable, Supplier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuppliersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, phone, note, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suppliers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Supplier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Supplier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Supplier(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SuppliersTable createAlias(String alias) {
    return $SuppliersTable(attachedDatabase, alias);
  }
}

class Supplier extends DataClass implements Insertable<Supplier> {
  final String id;
  final String name;
  final String phone;
  final String note;
  final DateTime? deletedAt;
  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SuppliersCompanion toCompanion(bool nullToAbsent) {
    return SuppliersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      note: Value(note),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Supplier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Supplier(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      note: serializer.fromJson<String>(json['note']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'note': serializer.toJson<String>(note),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? note,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Supplier(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    note: note ?? this.note,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Supplier copyWithCompanion(SuppliersCompanion data) {
    return Supplier(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      note: data.note.present ? data.note.value : this.note,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Supplier(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, note, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Supplier &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.note == this.note &&
          other.deletedAt == this.deletedAt);
}

class SuppliersCompanion extends UpdateCompanion<Supplier> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> note;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SuppliersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuppliersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Supplier> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? note,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuppliersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<String>? note,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SuppliersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuppliersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductStockTable extends ProductStock
    with TableInfo<$ProductStockTable, ProductStockData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductStockTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    storeId,
    qtyMilli,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_stock';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductStockData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  ProductStockData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductStockData(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductStockTable createAlias(String alias) {
    return $ProductStockTable(attachedDatabase, alias);
  }
}

class ProductStockData extends DataClass
    implements Insertable<ProductStockData> {
  final String productId;
  final String storeId;
  final int qtyMilli;
  final DateTime updatedAt;
  const ProductStockData({
    required this.productId,
    required this.storeId,
    required this.qtyMilli,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['store_id'] = Variable<String>(storeId);
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductStockCompanion toCompanion(bool nullToAbsent) {
    return ProductStockCompanion(
      productId: Value(productId),
      storeId: Value(storeId),
      qtyMilli: Value(qtyMilli),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductStockData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductStockData(
      productId: serializer.fromJson<String>(json['productId']),
      storeId: serializer.fromJson<String>(json['storeId']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'storeId': serializer.toJson<String>(storeId),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductStockData copyWith({
    String? productId,
    String? storeId,
    int? qtyMilli,
    DateTime? updatedAt,
  }) => ProductStockData(
    productId: productId ?? this.productId,
    storeId: storeId ?? this.storeId,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductStockData copyWithCompanion(ProductStockCompanion data) {
    return ProductStockData(
      productId: data.productId.present ? data.productId.value : this.productId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductStockData(')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, storeId, qtyMilli, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductStockData &&
          other.productId == this.productId &&
          other.storeId == this.storeId &&
          other.qtyMilli == this.qtyMilli &&
          other.updatedAt == this.updatedAt);
}

class ProductStockCompanion extends UpdateCompanion<ProductStockData> {
  final Value<String> productId;
  final Value<String> storeId;
  final Value<int> qtyMilli;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductStockCompanion({
    this.productId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductStockCompanion.insert({
    required String productId,
    required String storeId,
    required int qtyMilli,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       storeId = Value(storeId),
       qtyMilli = Value(qtyMilli),
       updatedAt = Value(updatedAt);
  static Insertable<ProductStockData> custom({
    Expression<String>? productId,
    Expression<String>? storeId,
    Expression<int>? qtyMilli,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (storeId != null) 'store_id': storeId,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductStockCompanion copyWith({
    Value<String>? productId,
    Value<String>? storeId,
    Value<int>? qtyMilli,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductStockCompanion(
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductStockCompanion(')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtEntriesTable extends DebtEntries
    with TableInfo<$DebtEntriesTable, DebtEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountTiyinMeta = const VerificationMeta(
    'amountTiyin',
  );
  @override
  late final GeneratedColumn<int> amountTiyin = GeneratedColumn<int>(
    'amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refundIdMeta = const VerificationMeta(
    'refundId',
  );
  @override
  late final GeneratedColumn<String> refundId = GeneratedColumn<String>(
    'refund_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _byUserIdMeta = const VerificationMeta(
    'byUserId',
  );
  @override
  late final GeneratedColumn<String> byUserId = GeneratedColumn<String>(
    'by_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    amountTiyin,
    type,
    saleId,
    refundId,
    shiftId,
    method,
    note,
    byUserId,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('amount_tiyin')) {
      context.handle(
        _amountTiyinMeta,
        amountTiyin.isAcceptableOrUnknown(
          data['amount_tiyin']!,
          _amountTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountTiyinMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    }
    if (data.containsKey('refund_id')) {
      context.handle(
        _refundIdMeta,
        refundId.isAcceptableOrUnknown(data['refund_id']!, _refundIdMeta),
      );
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('by_user_id')) {
      context.handle(
        _byUserIdMeta,
        byUserId.isAcceptableOrUnknown(data['by_user_id']!, _byUserIdMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      amountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_tiyin'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      ),
      refundId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_id'],
      ),
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      byUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}by_user_id'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $DebtEntriesTable createAlias(String alias) {
    return $DebtEntriesTable(attachedDatabase, alias);
  }
}

class DebtEntry extends DataClass implements Insertable<DebtEntry> {
  final String id;
  final String customerId;
  final int amountTiyin;

  /// `sale` / `payment` / `refund` / `adjustment`.
  final String type;
  final String? saleId;
  final String? refundId;
  final String? shiftId;

  /// To'lov usuli (`cash` / `card`), faqat `payment` da.
  final String? method;
  final String note;
  final String? byUserId;
  final DateTime at;
  const DebtEntry({
    required this.id,
    required this.customerId,
    required this.amountTiyin,
    required this.type,
    this.saleId,
    this.refundId,
    this.shiftId,
    this.method,
    required this.note,
    this.byUserId,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['amount_tiyin'] = Variable<int>(amountTiyin);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || saleId != null) {
      map['sale_id'] = Variable<String>(saleId);
    }
    if (!nullToAbsent || refundId != null) {
      map['refund_id'] = Variable<String>(refundId);
    }
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(method);
    }
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || byUserId != null) {
      map['by_user_id'] = Variable<String>(byUserId);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  DebtEntriesCompanion toCompanion(bool nullToAbsent) {
    return DebtEntriesCompanion(
      id: Value(id),
      customerId: Value(customerId),
      amountTiyin: Value(amountTiyin),
      type: Value(type),
      saleId: saleId == null && nullToAbsent
          ? const Value.absent()
          : Value(saleId),
      refundId: refundId == null && nullToAbsent
          ? const Value.absent()
          : Value(refundId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      method: method == null && nullToAbsent
          ? const Value.absent()
          : Value(method),
      note: Value(note),
      byUserId: byUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(byUserId),
      at: Value(at),
    );
  }

  factory DebtEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtEntry(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      amountTiyin: serializer.fromJson<int>(json['amountTiyin']),
      type: serializer.fromJson<String>(json['type']),
      saleId: serializer.fromJson<String?>(json['saleId']),
      refundId: serializer.fromJson<String?>(json['refundId']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      method: serializer.fromJson<String?>(json['method']),
      note: serializer.fromJson<String>(json['note']),
      byUserId: serializer.fromJson<String?>(json['byUserId']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'amountTiyin': serializer.toJson<int>(amountTiyin),
      'type': serializer.toJson<String>(type),
      'saleId': serializer.toJson<String?>(saleId),
      'refundId': serializer.toJson<String?>(refundId),
      'shiftId': serializer.toJson<String?>(shiftId),
      'method': serializer.toJson<String?>(method),
      'note': serializer.toJson<String>(note),
      'byUserId': serializer.toJson<String?>(byUserId),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  DebtEntry copyWith({
    String? id,
    String? customerId,
    int? amountTiyin,
    String? type,
    Value<String?> saleId = const Value.absent(),
    Value<String?> refundId = const Value.absent(),
    Value<String?> shiftId = const Value.absent(),
    Value<String?> method = const Value.absent(),
    String? note,
    Value<String?> byUserId = const Value.absent(),
    DateTime? at,
  }) => DebtEntry(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    amountTiyin: amountTiyin ?? this.amountTiyin,
    type: type ?? this.type,
    saleId: saleId.present ? saleId.value : this.saleId,
    refundId: refundId.present ? refundId.value : this.refundId,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    method: method.present ? method.value : this.method,
    note: note ?? this.note,
    byUserId: byUserId.present ? byUserId.value : this.byUserId,
    at: at ?? this.at,
  );
  DebtEntry copyWithCompanion(DebtEntriesCompanion data) {
    return DebtEntry(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      amountTiyin: data.amountTiyin.present
          ? data.amountTiyin.value
          : this.amountTiyin,
      type: data.type.present ? data.type.value : this.type,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      refundId: data.refundId.present ? data.refundId.value : this.refundId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      method: data.method.present ? data.method.value : this.method,
      note: data.note.present ? data.note.value : this.note,
      byUserId: data.byUserId.present ? data.byUserId.value : this.byUserId,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtEntry(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('amountTiyin: $amountTiyin, ')
          ..write('type: $type, ')
          ..write('saleId: $saleId, ')
          ..write('refundId: $refundId, ')
          ..write('shiftId: $shiftId, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('byUserId: $byUserId, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    amountTiyin,
    type,
    saleId,
    refundId,
    shiftId,
    method,
    note,
    byUserId,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtEntry &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.amountTiyin == this.amountTiyin &&
          other.type == this.type &&
          other.saleId == this.saleId &&
          other.refundId == this.refundId &&
          other.shiftId == this.shiftId &&
          other.method == this.method &&
          other.note == this.note &&
          other.byUserId == this.byUserId &&
          other.at == this.at);
}

class DebtEntriesCompanion extends UpdateCompanion<DebtEntry> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<int> amountTiyin;
  final Value<String> type;
  final Value<String?> saleId;
  final Value<String?> refundId;
  final Value<String?> shiftId;
  final Value<String?> method;
  final Value<String> note;
  final Value<String?> byUserId;
  final Value<DateTime> at;
  final Value<int> rowid;
  const DebtEntriesCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.amountTiyin = const Value.absent(),
    this.type = const Value.absent(),
    this.saleId = const Value.absent(),
    this.refundId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.byUserId = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtEntriesCompanion.insert({
    required String id,
    required String customerId,
    required int amountTiyin,
    required String type,
    this.saleId = const Value.absent(),
    this.refundId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.byUserId = const Value.absent(),
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       amountTiyin = Value(amountTiyin),
       type = Value(type),
       at = Value(at);
  static Insertable<DebtEntry> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<int>? amountTiyin,
    Expression<String>? type,
    Expression<String>? saleId,
    Expression<String>? refundId,
    Expression<String>? shiftId,
    Expression<String>? method,
    Expression<String>? note,
    Expression<String>? byUserId,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (amountTiyin != null) 'amount_tiyin': amountTiyin,
      if (type != null) 'type': type,
      if (saleId != null) 'sale_id': saleId,
      if (refundId != null) 'refund_id': refundId,
      if (shiftId != null) 'shift_id': shiftId,
      if (method != null) 'method': method,
      if (note != null) 'note': note,
      if (byUserId != null) 'by_user_id': byUserId,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<int>? amountTiyin,
    Value<String>? type,
    Value<String?>? saleId,
    Value<String?>? refundId,
    Value<String?>? shiftId,
    Value<String?>? method,
    Value<String>? note,
    Value<String?>? byUserId,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return DebtEntriesCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amountTiyin: amountTiyin ?? this.amountTiyin,
      type: type ?? this.type,
      saleId: saleId ?? this.saleId,
      refundId: refundId ?? this.refundId,
      shiftId: shiftId ?? this.shiftId,
      method: method ?? this.method,
      note: note ?? this.note,
      byUserId: byUserId ?? this.byUserId,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (amountTiyin.present) {
      map['amount_tiyin'] = Variable<int>(amountTiyin.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (refundId.present) {
      map['refund_id'] = Variable<String>(refundId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (byUserId.present) {
      map['by_user_id'] = Variable<String>(byUserId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtEntriesCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('amountTiyin: $amountTiyin, ')
          ..write('type: $type, ')
          ..write('saleId: $saleId, ')
          ..write('refundId: $refundId, ')
          ..write('shiftId: $shiftId, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('byUserId: $byUserId, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTable extends Shifts with TableInfo<$ShiftsTable, Shift> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedByMeta = const VerificationMeta(
    'openedBy',
  );
  @override
  late final GeneratedColumn<String> openedBy = GeneratedColumn<String>(
    'opened_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingCashTiyinMeta = const VerificationMeta(
    'openingCashTiyin',
  );
  @override
  late final GeneratedColumn<int> openingCashTiyin = GeneratedColumn<int>(
    'opening_cash_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedByMeta = const VerificationMeta(
    'closedBy',
  );
  @override
  late final GeneratedColumn<String> closedBy = GeneratedColumn<String>(
    'closed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countedCashTiyinMeta = const VerificationMeta(
    'countedCashTiyin',
  );
  @override
  late final GeneratedColumn<int> countedCashTiyin = GeneratedColumn<int>(
    'counted_cash_tiyin',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedCashTiyinMeta = const VerificationMeta(
    'expectedCashTiyin',
  );
  @override
  late final GeneratedColumn<int> expectedCashTiyin = GeneratedColumn<int>(
    'expected_cash_tiyin',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    deviceId,
    openedBy,
    openedAt,
    openingCashTiyin,
    closedBy,
    closedAt,
    countedCashTiyin,
    expectedCashTiyin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shift> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('opened_by')) {
      context.handle(
        _openedByMeta,
        openedBy.isAcceptableOrUnknown(data['opened_by']!, _openedByMeta),
      );
    } else if (isInserting) {
      context.missing(_openedByMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('opening_cash_tiyin')) {
      context.handle(
        _openingCashTiyinMeta,
        openingCashTiyin.isAcceptableOrUnknown(
          data['opening_cash_tiyin']!,
          _openingCashTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingCashTiyinMeta);
    }
    if (data.containsKey('closed_by')) {
      context.handle(
        _closedByMeta,
        closedBy.isAcceptableOrUnknown(data['closed_by']!, _closedByMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('counted_cash_tiyin')) {
      context.handle(
        _countedCashTiyinMeta,
        countedCashTiyin.isAcceptableOrUnknown(
          data['counted_cash_tiyin']!,
          _countedCashTiyinMeta,
        ),
      );
    }
    if (data.containsKey('expected_cash_tiyin')) {
      context.handle(
        _expectedCashTiyinMeta,
        expectedCashTiyin.isAcceptableOrUnknown(
          data['expected_cash_tiyin']!,
          _expectedCashTiyinMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shift map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shift(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      openedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_by'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      openingCashTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_cash_tiyin'],
      )!,
      closedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by'],
      ),
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      countedCashTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counted_cash_tiyin'],
      ),
      expectedCashTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_cash_tiyin'],
      ),
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }
}

class Shift extends DataClass implements Insertable<Shift> {
  final String id;
  final String storeId;
  final String deviceId;
  final String openedBy;
  final DateTime openedAt;
  final int openingCashTiyin;
  final String? closedBy;
  final DateTime? closedAt;
  final int? countedCashTiyin;
  final int? expectedCashTiyin;
  const Shift({
    required this.id,
    required this.storeId,
    required this.deviceId,
    required this.openedBy,
    required this.openedAt,
    required this.openingCashTiyin,
    this.closedBy,
    this.closedAt,
    this.countedCashTiyin,
    this.expectedCashTiyin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['device_id'] = Variable<String>(deviceId);
    map['opened_by'] = Variable<String>(openedBy);
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['opening_cash_tiyin'] = Variable<int>(openingCashTiyin);
    if (!nullToAbsent || closedBy != null) {
      map['closed_by'] = Variable<String>(closedBy);
    }
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || countedCashTiyin != null) {
      map['counted_cash_tiyin'] = Variable<int>(countedCashTiyin);
    }
    if (!nullToAbsent || expectedCashTiyin != null) {
      map['expected_cash_tiyin'] = Variable<int>(expectedCashTiyin);
    }
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      deviceId: Value(deviceId),
      openedBy: Value(openedBy),
      openedAt: Value(openedAt),
      openingCashTiyin: Value(openingCashTiyin),
      closedBy: closedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(closedBy),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      countedCashTiyin: countedCashTiyin == null && nullToAbsent
          ? const Value.absent()
          : Value(countedCashTiyin),
      expectedCashTiyin: expectedCashTiyin == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCashTiyin),
    );
  }

  factory Shift.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shift(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      openedBy: serializer.fromJson<String>(json['openedBy']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      openingCashTiyin: serializer.fromJson<int>(json['openingCashTiyin']),
      closedBy: serializer.fromJson<String?>(json['closedBy']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      countedCashTiyin: serializer.fromJson<int?>(json['countedCashTiyin']),
      expectedCashTiyin: serializer.fromJson<int?>(json['expectedCashTiyin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'deviceId': serializer.toJson<String>(deviceId),
      'openedBy': serializer.toJson<String>(openedBy),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'openingCashTiyin': serializer.toJson<int>(openingCashTiyin),
      'closedBy': serializer.toJson<String?>(closedBy),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'countedCashTiyin': serializer.toJson<int?>(countedCashTiyin),
      'expectedCashTiyin': serializer.toJson<int?>(expectedCashTiyin),
    };
  }

  Shift copyWith({
    String? id,
    String? storeId,
    String? deviceId,
    String? openedBy,
    DateTime? openedAt,
    int? openingCashTiyin,
    Value<String?> closedBy = const Value.absent(),
    Value<DateTime?> closedAt = const Value.absent(),
    Value<int?> countedCashTiyin = const Value.absent(),
    Value<int?> expectedCashTiyin = const Value.absent(),
  }) => Shift(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    deviceId: deviceId ?? this.deviceId,
    openedBy: openedBy ?? this.openedBy,
    openedAt: openedAt ?? this.openedAt,
    openingCashTiyin: openingCashTiyin ?? this.openingCashTiyin,
    closedBy: closedBy.present ? closedBy.value : this.closedBy,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    countedCashTiyin: countedCashTiyin.present
        ? countedCashTiyin.value
        : this.countedCashTiyin,
    expectedCashTiyin: expectedCashTiyin.present
        ? expectedCashTiyin.value
        : this.expectedCashTiyin,
  );
  Shift copyWithCompanion(ShiftsCompanion data) {
    return Shift(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      openedBy: data.openedBy.present ? data.openedBy.value : this.openedBy,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      openingCashTiyin: data.openingCashTiyin.present
          ? data.openingCashTiyin.value
          : this.openingCashTiyin,
      closedBy: data.closedBy.present ? data.closedBy.value : this.closedBy,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      countedCashTiyin: data.countedCashTiyin.present
          ? data.countedCashTiyin.value
          : this.countedCashTiyin,
      expectedCashTiyin: data.expectedCashTiyin.present
          ? data.expectedCashTiyin.value
          : this.expectedCashTiyin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shift(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('deviceId: $deviceId, ')
          ..write('openedBy: $openedBy, ')
          ..write('openedAt: $openedAt, ')
          ..write('openingCashTiyin: $openingCashTiyin, ')
          ..write('closedBy: $closedBy, ')
          ..write('closedAt: $closedAt, ')
          ..write('countedCashTiyin: $countedCashTiyin, ')
          ..write('expectedCashTiyin: $expectedCashTiyin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    deviceId,
    openedBy,
    openedAt,
    openingCashTiyin,
    closedBy,
    closedAt,
    countedCashTiyin,
    expectedCashTiyin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shift &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.deviceId == this.deviceId &&
          other.openedBy == this.openedBy &&
          other.openedAt == this.openedAt &&
          other.openingCashTiyin == this.openingCashTiyin &&
          other.closedBy == this.closedBy &&
          other.closedAt == this.closedAt &&
          other.countedCashTiyin == this.countedCashTiyin &&
          other.expectedCashTiyin == this.expectedCashTiyin);
}

class ShiftsCompanion extends UpdateCompanion<Shift> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> deviceId;
  final Value<String> openedBy;
  final Value<DateTime> openedAt;
  final Value<int> openingCashTiyin;
  final Value<String?> closedBy;
  final Value<DateTime?> closedAt;
  final Value<int?> countedCashTiyin;
  final Value<int?> expectedCashTiyin;
  final Value<int> rowid;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.openedBy = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openingCashTiyin = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.countedCashTiyin = const Value.absent(),
    this.expectedCashTiyin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftsCompanion.insert({
    required String id,
    required String storeId,
    required String deviceId,
    required String openedBy,
    required DateTime openedAt,
    required int openingCashTiyin,
    this.closedBy = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.countedCashTiyin = const Value.absent(),
    this.expectedCashTiyin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       deviceId = Value(deviceId),
       openedBy = Value(openedBy),
       openedAt = Value(openedAt),
       openingCashTiyin = Value(openingCashTiyin);
  static Insertable<Shift> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? deviceId,
    Expression<String>? openedBy,
    Expression<DateTime>? openedAt,
    Expression<int>? openingCashTiyin,
    Expression<String>? closedBy,
    Expression<DateTime>? closedAt,
    Expression<int>? countedCashTiyin,
    Expression<int>? expectedCashTiyin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (deviceId != null) 'device_id': deviceId,
      if (openedBy != null) 'opened_by': openedBy,
      if (openedAt != null) 'opened_at': openedAt,
      if (openingCashTiyin != null) 'opening_cash_tiyin': openingCashTiyin,
      if (closedBy != null) 'closed_by': closedBy,
      if (closedAt != null) 'closed_at': closedAt,
      if (countedCashTiyin != null) 'counted_cash_tiyin': countedCashTiyin,
      if (expectedCashTiyin != null) 'expected_cash_tiyin': expectedCashTiyin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftsCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? deviceId,
    Value<String>? openedBy,
    Value<DateTime>? openedAt,
    Value<int>? openingCashTiyin,
    Value<String?>? closedBy,
    Value<DateTime?>? closedAt,
    Value<int?>? countedCashTiyin,
    Value<int?>? expectedCashTiyin,
    Value<int>? rowid,
  }) {
    return ShiftsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      deviceId: deviceId ?? this.deviceId,
      openedBy: openedBy ?? this.openedBy,
      openedAt: openedAt ?? this.openedAt,
      openingCashTiyin: openingCashTiyin ?? this.openingCashTiyin,
      closedBy: closedBy ?? this.closedBy,
      closedAt: closedAt ?? this.closedAt,
      countedCashTiyin: countedCashTiyin ?? this.countedCashTiyin,
      expectedCashTiyin: expectedCashTiyin ?? this.expectedCashTiyin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (openedBy.present) {
      map['opened_by'] = Variable<String>(openedBy.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (openingCashTiyin.present) {
      map['opening_cash_tiyin'] = Variable<int>(openingCashTiyin.value);
    }
    if (closedBy.present) {
      map['closed_by'] = Variable<String>(closedBy.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (countedCashTiyin.present) {
      map['counted_cash_tiyin'] = Variable<int>(countedCashTiyin.value);
    }
    if (expectedCashTiyin.present) {
      map['expected_cash_tiyin'] = Variable<int>(expectedCashTiyin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('deviceId: $deviceId, ')
          ..write('openedBy: $openedBy, ')
          ..write('openedAt: $openedAt, ')
          ..write('openingCashTiyin: $openingCashTiyin, ')
          ..write('closedBy: $closedBy, ')
          ..write('closedAt: $closedAt, ')
          ..write('countedCashTiyin: $countedCashTiyin, ')
          ..write('expectedCashTiyin: $expectedCashTiyin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _subtotalTiyinMeta = const VerificationMeta(
    'subtotalTiyin',
  );
  @override
  late final GeneratedColumn<int> subtotalTiyin = GeneratedColumn<int>(
    'subtotal_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTiyinMeta = const VerificationMeta(
    'discountTiyin',
  );
  @override
  late final GeneratedColumn<int> discountTiyin = GeneratedColumn<int>(
    'discount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTiyinMeta = const VerificationMeta(
    'totalTiyin',
  );
  @override
  late final GeneratedColumn<int> totalTiyin = GeneratedColumn<int>(
    'total_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _debtEntryIdMeta = const VerificationMeta(
    'debtEntryId',
  );
  @override
  late final GeneratedColumn<String> debtEntryId = GeneratedColumn<String>(
    'debt_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soldAtMeta = const VerificationMeta('soldAt');
  @override
  late final GeneratedColumn<DateTime> soldAt = GeneratedColumn<DateTime>(
    'sold_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shiftId,
    cashierId,
    customerId,
    approvedBy,
    number,
    subtotalTiyin,
    discountTiyin,
    totalTiyin,
    status,
    debtEntryId,
    soldAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('subtotal_tiyin')) {
      context.handle(
        _subtotalTiyinMeta,
        subtotalTiyin.isAcceptableOrUnknown(
          data['subtotal_tiyin']!,
          _subtotalTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtotalTiyinMeta);
    }
    if (data.containsKey('discount_tiyin')) {
      context.handle(
        _discountTiyinMeta,
        discountTiyin.isAcceptableOrUnknown(
          data['discount_tiyin']!,
          _discountTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountTiyinMeta);
    }
    if (data.containsKey('total_tiyin')) {
      context.handle(
        _totalTiyinMeta,
        totalTiyin.isAcceptableOrUnknown(data['total_tiyin']!, _totalTiyinMeta),
      );
    } else if (isInserting) {
      context.missing(_totalTiyinMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('debt_entry_id')) {
      context.handle(
        _debtEntryIdMeta,
        debtEntryId.isAcceptableOrUnknown(
          data['debt_entry_id']!,
          _debtEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('sold_at')) {
      context.handle(
        _soldAtMeta,
        soldAt.isAcceptableOrUnknown(data['sold_at']!, _soldAtMeta),
      );
    } else if (isInserting) {
      context.missing(_soldAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      subtotalTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_tiyin'],
      )!,
      discountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_tiyin'],
      )!,
      totalTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_tiyin'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      debtEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_entry_id'],
      ),
      soldAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sold_at'],
      )!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final String id;
  final String shiftId;
  final String cashierId;
  final String? customerId;

  /// Menejer ruxsati (qarz limiti, narx o'zgarishi).
  final String? approvedBy;

  /// Qurilma ichida ketma-ket: `D3-000123`.
  final String number;
  final int subtotalTiyin;
  final int discountTiyin;
  final int totalTiyin;

  /// `completed` / `partially_refunded` / `refunded`.
  final String status;
  final String? debtEntryId;
  final DateTime soldAt;
  const Sale({
    required this.id,
    required this.shiftId,
    required this.cashierId,
    this.customerId,
    this.approvedBy,
    required this.number,
    required this.subtotalTiyin,
    required this.discountTiyin,
    required this.totalTiyin,
    required this.status,
    this.debtEntryId,
    required this.soldAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shift_id'] = Variable<String>(shiftId);
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    map['number'] = Variable<String>(number);
    map['subtotal_tiyin'] = Variable<int>(subtotalTiyin);
    map['discount_tiyin'] = Variable<int>(discountTiyin);
    map['total_tiyin'] = Variable<int>(totalTiyin);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || debtEntryId != null) {
      map['debt_entry_id'] = Variable<String>(debtEntryId);
    }
    map['sold_at'] = Variable<DateTime>(soldAt);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      cashierId: Value(cashierId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
      number: Value(number),
      subtotalTiyin: Value(subtotalTiyin),
      discountTiyin: Value(discountTiyin),
      totalTiyin: Value(totalTiyin),
      status: Value(status),
      debtEntryId: debtEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(debtEntryId),
      soldAt: Value(soldAt),
    );
  }

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<String>(json['id']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      number: serializer.fromJson<String>(json['number']),
      subtotalTiyin: serializer.fromJson<int>(json['subtotalTiyin']),
      discountTiyin: serializer.fromJson<int>(json['discountTiyin']),
      totalTiyin: serializer.fromJson<int>(json['totalTiyin']),
      status: serializer.fromJson<String>(json['status']),
      debtEntryId: serializer.fromJson<String?>(json['debtEntryId']),
      soldAt: serializer.fromJson<DateTime>(json['soldAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shiftId': serializer.toJson<String>(shiftId),
      'cashierId': serializer.toJson<String>(cashierId),
      'customerId': serializer.toJson<String?>(customerId),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'number': serializer.toJson<String>(number),
      'subtotalTiyin': serializer.toJson<int>(subtotalTiyin),
      'discountTiyin': serializer.toJson<int>(discountTiyin),
      'totalTiyin': serializer.toJson<int>(totalTiyin),
      'status': serializer.toJson<String>(status),
      'debtEntryId': serializer.toJson<String?>(debtEntryId),
      'soldAt': serializer.toJson<DateTime>(soldAt),
    };
  }

  Sale copyWith({
    String? id,
    String? shiftId,
    String? cashierId,
    Value<String?> customerId = const Value.absent(),
    Value<String?> approvedBy = const Value.absent(),
    String? number,
    int? subtotalTiyin,
    int? discountTiyin,
    int? totalTiyin,
    String? status,
    Value<String?> debtEntryId = const Value.absent(),
    DateTime? soldAt,
  }) => Sale(
    id: id ?? this.id,
    shiftId: shiftId ?? this.shiftId,
    cashierId: cashierId ?? this.cashierId,
    customerId: customerId.present ? customerId.value : this.customerId,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    number: number ?? this.number,
    subtotalTiyin: subtotalTiyin ?? this.subtotalTiyin,
    discountTiyin: discountTiyin ?? this.discountTiyin,
    totalTiyin: totalTiyin ?? this.totalTiyin,
    status: status ?? this.status,
    debtEntryId: debtEntryId.present ? debtEntryId.value : this.debtEntryId,
    soldAt: soldAt ?? this.soldAt,
  );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      number: data.number.present ? data.number.value : this.number,
      subtotalTiyin: data.subtotalTiyin.present
          ? data.subtotalTiyin.value
          : this.subtotalTiyin,
      discountTiyin: data.discountTiyin.present
          ? data.discountTiyin.value
          : this.discountTiyin,
      totalTiyin: data.totalTiyin.present
          ? data.totalTiyin.value
          : this.totalTiyin,
      status: data.status.present ? data.status.value : this.status,
      debtEntryId: data.debtEntryId.present
          ? data.debtEntryId.value
          : this.debtEntryId,
      soldAt: data.soldAt.present ? data.soldAt.value : this.soldAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('cashierId: $cashierId, ')
          ..write('customerId: $customerId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('number: $number, ')
          ..write('subtotalTiyin: $subtotalTiyin, ')
          ..write('discountTiyin: $discountTiyin, ')
          ..write('totalTiyin: $totalTiyin, ')
          ..write('status: $status, ')
          ..write('debtEntryId: $debtEntryId, ')
          ..write('soldAt: $soldAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shiftId,
    cashierId,
    customerId,
    approvedBy,
    number,
    subtotalTiyin,
    discountTiyin,
    totalTiyin,
    status,
    debtEntryId,
    soldAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.cashierId == this.cashierId &&
          other.customerId == this.customerId &&
          other.approvedBy == this.approvedBy &&
          other.number == this.number &&
          other.subtotalTiyin == this.subtotalTiyin &&
          other.discountTiyin == this.discountTiyin &&
          other.totalTiyin == this.totalTiyin &&
          other.status == this.status &&
          other.debtEntryId == this.debtEntryId &&
          other.soldAt == this.soldAt);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<String> id;
  final Value<String> shiftId;
  final Value<String> cashierId;
  final Value<String?> customerId;
  final Value<String?> approvedBy;
  final Value<String> number;
  final Value<int> subtotalTiyin;
  final Value<int> discountTiyin;
  final Value<int> totalTiyin;
  final Value<String> status;
  final Value<String?> debtEntryId;
  final Value<DateTime> soldAt;
  final Value<int> rowid;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.number = const Value.absent(),
    this.subtotalTiyin = const Value.absent(),
    this.discountTiyin = const Value.absent(),
    this.totalTiyin = const Value.absent(),
    this.status = const Value.absent(),
    this.debtEntryId = const Value.absent(),
    this.soldAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesCompanion.insert({
    required String id,
    required String shiftId,
    required String cashierId,
    this.customerId = const Value.absent(),
    this.approvedBy = const Value.absent(),
    required String number,
    required int subtotalTiyin,
    required int discountTiyin,
    required int totalTiyin,
    this.status = const Value.absent(),
    this.debtEntryId = const Value.absent(),
    required DateTime soldAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shiftId = Value(shiftId),
       cashierId = Value(cashierId),
       number = Value(number),
       subtotalTiyin = Value(subtotalTiyin),
       discountTiyin = Value(discountTiyin),
       totalTiyin = Value(totalTiyin),
       soldAt = Value(soldAt);
  static Insertable<Sale> custom({
    Expression<String>? id,
    Expression<String>? shiftId,
    Expression<String>? cashierId,
    Expression<String>? customerId,
    Expression<String>? approvedBy,
    Expression<String>? number,
    Expression<int>? subtotalTiyin,
    Expression<int>? discountTiyin,
    Expression<int>? totalTiyin,
    Expression<String>? status,
    Expression<String>? debtEntryId,
    Expression<DateTime>? soldAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (customerId != null) 'customer_id': customerId,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (number != null) 'number': number,
      if (subtotalTiyin != null) 'subtotal_tiyin': subtotalTiyin,
      if (discountTiyin != null) 'discount_tiyin': discountTiyin,
      if (totalTiyin != null) 'total_tiyin': totalTiyin,
      if (status != null) 'status': status,
      if (debtEntryId != null) 'debt_entry_id': debtEntryId,
      if (soldAt != null) 'sold_at': soldAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesCompanion copyWith({
    Value<String>? id,
    Value<String>? shiftId,
    Value<String>? cashierId,
    Value<String?>? customerId,
    Value<String?>? approvedBy,
    Value<String>? number,
    Value<int>? subtotalTiyin,
    Value<int>? discountTiyin,
    Value<int>? totalTiyin,
    Value<String>? status,
    Value<String?>? debtEntryId,
    Value<DateTime>? soldAt,
    Value<int>? rowid,
  }) {
    return SalesCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      cashierId: cashierId ?? this.cashierId,
      customerId: customerId ?? this.customerId,
      approvedBy: approvedBy ?? this.approvedBy,
      number: number ?? this.number,
      subtotalTiyin: subtotalTiyin ?? this.subtotalTiyin,
      discountTiyin: discountTiyin ?? this.discountTiyin,
      totalTiyin: totalTiyin ?? this.totalTiyin,
      status: status ?? this.status,
      debtEntryId: debtEntryId ?? this.debtEntryId,
      soldAt: soldAt ?? this.soldAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (subtotalTiyin.present) {
      map['subtotal_tiyin'] = Variable<int>(subtotalTiyin.value);
    }
    if (discountTiyin.present) {
      map['discount_tiyin'] = Variable<int>(discountTiyin.value);
    }
    if (totalTiyin.present) {
      map['total_tiyin'] = Variable<int>(totalTiyin.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (debtEntryId.present) {
      map['debt_entry_id'] = Variable<String>(debtEntryId.value);
    }
    if (soldAt.present) {
      map['sold_at'] = Variable<DateTime>(soldAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('cashierId: $cashierId, ')
          ..write('customerId: $customerId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('number: $number, ')
          ..write('subtotalTiyin: $subtotalTiyin, ')
          ..write('discountTiyin: $discountTiyin, ')
          ..write('totalTiyin: $totalTiyin, ')
          ..write('status: $status, ')
          ..write('debtEntryId: $debtEntryId, ')
          ..write('soldAt: $soldAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleItemsTable extends SaleItems
    with TableInfo<$SaleItemsTable, SaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameSnapshotMeta = const VerificationMeta(
    'nameSnapshot',
  );
  @override
  late final GeneratedColumn<String> nameSnapshot = GeneratedColumn<String>(
    'name_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeSnapshotMeta = const VerificationMeta(
    'barcodeSnapshot',
  );
  @override
  late final GeneratedColumn<String> barcodeSnapshot = GeneratedColumn<String>(
    'barcode_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceTiyinMeta = const VerificationMeta(
    'priceTiyin',
  );
  @override
  late final GeneratedColumn<int> priceTiyin = GeneratedColumn<int>(
    'price_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costTiyinMeta = const VerificationMeta(
    'costTiyin',
  );
  @override
  late final GeneratedColumn<int> costTiyin = GeneratedColumn<int>(
    'cost_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTiyinMeta = const VerificationMeta(
    'discountTiyin',
  );
  @override
  late final GeneratedColumn<int> discountTiyin = GeneratedColumn<int>(
    'discount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTiyinMeta = const VerificationMeta(
    'totalTiyin',
  );
  @override
  late final GeneratedColumn<int> totalTiyin = GeneratedColumn<int>(
    'total_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    position,
    productId,
    nameSnapshot,
    barcodeSnapshot,
    qtyMilli,
    priceTiyin,
    costTiyin,
    discountTiyin,
    totalTiyin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('name_snapshot')) {
      context.handle(
        _nameSnapshotMeta,
        nameSnapshot.isAcceptableOrUnknown(
          data['name_snapshot']!,
          _nameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameSnapshotMeta);
    }
    if (data.containsKey('barcode_snapshot')) {
      context.handle(
        _barcodeSnapshotMeta,
        barcodeSnapshot.isAcceptableOrUnknown(
          data['barcode_snapshot']!,
          _barcodeSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('price_tiyin')) {
      context.handle(
        _priceTiyinMeta,
        priceTiyin.isAcceptableOrUnknown(data['price_tiyin']!, _priceTiyinMeta),
      );
    } else if (isInserting) {
      context.missing(_priceTiyinMeta);
    }
    if (data.containsKey('cost_tiyin')) {
      context.handle(
        _costTiyinMeta,
        costTiyin.isAcceptableOrUnknown(data['cost_tiyin']!, _costTiyinMeta),
      );
    } else if (isInserting) {
      context.missing(_costTiyinMeta);
    }
    if (data.containsKey('discount_tiyin')) {
      context.handle(
        _discountTiyinMeta,
        discountTiyin.isAcceptableOrUnknown(
          data['discount_tiyin']!,
          _discountTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountTiyinMeta);
    }
    if (data.containsKey('total_tiyin')) {
      context.handle(
        _totalTiyinMeta,
        totalTiyin.isAcceptableOrUnknown(data['total_tiyin']!, _totalTiyinMeta),
      );
    } else if (isInserting) {
      context.missing(_totalTiyinMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      nameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_snapshot'],
      )!,
      barcodeSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_snapshot'],
      ),
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      priceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_tiyin'],
      )!,
      costTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_tiyin'],
      )!,
      discountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_tiyin'],
      )!,
      totalTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_tiyin'],
      )!,
    );
  }

  @override
  $SaleItemsTable createAlias(String alias) {
    return $SaleItemsTable(attachedDatabase, alias);
  }
}

class SaleItem extends DataClass implements Insertable<SaleItem> {
  final String id;
  final String saleId;

  /// Chekdagi tartib (0 dan).
  final int position;
  final String productId;
  final String nameSnapshot;
  final String? barcodeSnapshot;
  final int qtyMilli;
  final int priceTiyin;
  final int costTiyin;
  final int discountTiyin;
  final int totalTiyin;
  const SaleItem({
    required this.id,
    required this.saleId,
    required this.position,
    required this.productId,
    required this.nameSnapshot,
    this.barcodeSnapshot,
    required this.qtyMilli,
    required this.priceTiyin,
    required this.costTiyin,
    required this.discountTiyin,
    required this.totalTiyin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['position'] = Variable<int>(position);
    map['product_id'] = Variable<String>(productId);
    map['name_snapshot'] = Variable<String>(nameSnapshot);
    if (!nullToAbsent || barcodeSnapshot != null) {
      map['barcode_snapshot'] = Variable<String>(barcodeSnapshot);
    }
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['price_tiyin'] = Variable<int>(priceTiyin);
    map['cost_tiyin'] = Variable<int>(costTiyin);
    map['discount_tiyin'] = Variable<int>(discountTiyin);
    map['total_tiyin'] = Variable<int>(totalTiyin);
    return map;
  }

  SaleItemsCompanion toCompanion(bool nullToAbsent) {
    return SaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      position: Value(position),
      productId: Value(productId),
      nameSnapshot: Value(nameSnapshot),
      barcodeSnapshot: barcodeSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(barcodeSnapshot),
      qtyMilli: Value(qtyMilli),
      priceTiyin: Value(priceTiyin),
      costTiyin: Value(costTiyin),
      discountTiyin: Value(discountTiyin),
      totalTiyin: Value(totalTiyin),
    );
  }

  factory SaleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItem(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      position: serializer.fromJson<int>(json['position']),
      productId: serializer.fromJson<String>(json['productId']),
      nameSnapshot: serializer.fromJson<String>(json['nameSnapshot']),
      barcodeSnapshot: serializer.fromJson<String?>(json['barcodeSnapshot']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      priceTiyin: serializer.fromJson<int>(json['priceTiyin']),
      costTiyin: serializer.fromJson<int>(json['costTiyin']),
      discountTiyin: serializer.fromJson<int>(json['discountTiyin']),
      totalTiyin: serializer.fromJson<int>(json['totalTiyin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'position': serializer.toJson<int>(position),
      'productId': serializer.toJson<String>(productId),
      'nameSnapshot': serializer.toJson<String>(nameSnapshot),
      'barcodeSnapshot': serializer.toJson<String?>(barcodeSnapshot),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'priceTiyin': serializer.toJson<int>(priceTiyin),
      'costTiyin': serializer.toJson<int>(costTiyin),
      'discountTiyin': serializer.toJson<int>(discountTiyin),
      'totalTiyin': serializer.toJson<int>(totalTiyin),
    };
  }

  SaleItem copyWith({
    String? id,
    String? saleId,
    int? position,
    String? productId,
    String? nameSnapshot,
    Value<String?> barcodeSnapshot = const Value.absent(),
    int? qtyMilli,
    int? priceTiyin,
    int? costTiyin,
    int? discountTiyin,
    int? totalTiyin,
  }) => SaleItem(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    position: position ?? this.position,
    productId: productId ?? this.productId,
    nameSnapshot: nameSnapshot ?? this.nameSnapshot,
    barcodeSnapshot: barcodeSnapshot.present
        ? barcodeSnapshot.value
        : this.barcodeSnapshot,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    priceTiyin: priceTiyin ?? this.priceTiyin,
    costTiyin: costTiyin ?? this.costTiyin,
    discountTiyin: discountTiyin ?? this.discountTiyin,
    totalTiyin: totalTiyin ?? this.totalTiyin,
  );
  SaleItem copyWithCompanion(SaleItemsCompanion data) {
    return SaleItem(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      position: data.position.present ? data.position.value : this.position,
      productId: data.productId.present ? data.productId.value : this.productId,
      nameSnapshot: data.nameSnapshot.present
          ? data.nameSnapshot.value
          : this.nameSnapshot,
      barcodeSnapshot: data.barcodeSnapshot.present
          ? data.barcodeSnapshot.value
          : this.barcodeSnapshot,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      priceTiyin: data.priceTiyin.present
          ? data.priceTiyin.value
          : this.priceTiyin,
      costTiyin: data.costTiyin.present ? data.costTiyin.value : this.costTiyin,
      discountTiyin: data.discountTiyin.present
          ? data.discountTiyin.value
          : this.discountTiyin,
      totalTiyin: data.totalTiyin.present
          ? data.totalTiyin.value
          : this.totalTiyin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItem(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('position: $position, ')
          ..write('productId: $productId, ')
          ..write('nameSnapshot: $nameSnapshot, ')
          ..write('barcodeSnapshot: $barcodeSnapshot, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('priceTiyin: $priceTiyin, ')
          ..write('costTiyin: $costTiyin, ')
          ..write('discountTiyin: $discountTiyin, ')
          ..write('totalTiyin: $totalTiyin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    position,
    productId,
    nameSnapshot,
    barcodeSnapshot,
    qtyMilli,
    priceTiyin,
    costTiyin,
    discountTiyin,
    totalTiyin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItem &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.position == this.position &&
          other.productId == this.productId &&
          other.nameSnapshot == this.nameSnapshot &&
          other.barcodeSnapshot == this.barcodeSnapshot &&
          other.qtyMilli == this.qtyMilli &&
          other.priceTiyin == this.priceTiyin &&
          other.costTiyin == this.costTiyin &&
          other.discountTiyin == this.discountTiyin &&
          other.totalTiyin == this.totalTiyin);
}

class SaleItemsCompanion extends UpdateCompanion<SaleItem> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<int> position;
  final Value<String> productId;
  final Value<String> nameSnapshot;
  final Value<String?> barcodeSnapshot;
  final Value<int> qtyMilli;
  final Value<int> priceTiyin;
  final Value<int> costTiyin;
  final Value<int> discountTiyin;
  final Value<int> totalTiyin;
  final Value<int> rowid;
  const SaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.position = const Value.absent(),
    this.productId = const Value.absent(),
    this.nameSnapshot = const Value.absent(),
    this.barcodeSnapshot = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.priceTiyin = const Value.absent(),
    this.costTiyin = const Value.absent(),
    this.discountTiyin = const Value.absent(),
    this.totalTiyin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleItemsCompanion.insert({
    required String id,
    required String saleId,
    required int position,
    required String productId,
    required String nameSnapshot,
    this.barcodeSnapshot = const Value.absent(),
    required int qtyMilli,
    required int priceTiyin,
    required int costTiyin,
    required int discountTiyin,
    required int totalTiyin,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       position = Value(position),
       productId = Value(productId),
       nameSnapshot = Value(nameSnapshot),
       qtyMilli = Value(qtyMilli),
       priceTiyin = Value(priceTiyin),
       costTiyin = Value(costTiyin),
       discountTiyin = Value(discountTiyin),
       totalTiyin = Value(totalTiyin);
  static Insertable<SaleItem> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<int>? position,
    Expression<String>? productId,
    Expression<String>? nameSnapshot,
    Expression<String>? barcodeSnapshot,
    Expression<int>? qtyMilli,
    Expression<int>? priceTiyin,
    Expression<int>? costTiyin,
    Expression<int>? discountTiyin,
    Expression<int>? totalTiyin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (position != null) 'position': position,
      if (productId != null) 'product_id': productId,
      if (nameSnapshot != null) 'name_snapshot': nameSnapshot,
      if (barcodeSnapshot != null) 'barcode_snapshot': barcodeSnapshot,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (priceTiyin != null) 'price_tiyin': priceTiyin,
      if (costTiyin != null) 'cost_tiyin': costTiyin,
      if (discountTiyin != null) 'discount_tiyin': discountTiyin,
      if (totalTiyin != null) 'total_tiyin': totalTiyin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<int>? position,
    Value<String>? productId,
    Value<String>? nameSnapshot,
    Value<String?>? barcodeSnapshot,
    Value<int>? qtyMilli,
    Value<int>? priceTiyin,
    Value<int>? costTiyin,
    Value<int>? discountTiyin,
    Value<int>? totalTiyin,
    Value<int>? rowid,
  }) {
    return SaleItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      position: position ?? this.position,
      productId: productId ?? this.productId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      barcodeSnapshot: barcodeSnapshot ?? this.barcodeSnapshot,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      priceTiyin: priceTiyin ?? this.priceTiyin,
      costTiyin: costTiyin ?? this.costTiyin,
      discountTiyin: discountTiyin ?? this.discountTiyin,
      totalTiyin: totalTiyin ?? this.totalTiyin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (nameSnapshot.present) {
      map['name_snapshot'] = Variable<String>(nameSnapshot.value);
    }
    if (barcodeSnapshot.present) {
      map['barcode_snapshot'] = Variable<String>(barcodeSnapshot.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (priceTiyin.present) {
      map['price_tiyin'] = Variable<int>(priceTiyin.value);
    }
    if (costTiyin.present) {
      map['cost_tiyin'] = Variable<int>(costTiyin.value);
    }
    if (discountTiyin.present) {
      map['discount_tiyin'] = Variable<int>(discountTiyin.value);
    }
    if (totalTiyin.present) {
      map['total_tiyin'] = Variable<int>(totalTiyin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('position: $position, ')
          ..write('productId: $productId, ')
          ..write('nameSnapshot: $nameSnapshot, ')
          ..write('barcodeSnapshot: $barcodeSnapshot, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('priceTiyin: $priceTiyin, ')
          ..write('costTiyin: $costTiyin, ')
          ..write('discountTiyin: $discountTiyin, ')
          ..write('totalTiyin: $totalTiyin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalePaymentsTable extends SalePayments
    with TableInfo<$SalePaymentsTable, SalePayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalePaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountTiyinMeta = const VerificationMeta(
    'amountTiyin',
  );
  @override
  late final GeneratedColumn<int> amountTiyin = GeneratedColumn<int>(
    'amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedTiyinMeta = const VerificationMeta(
    'receivedTiyin',
  );
  @override
  late final GeneratedColumn<int> receivedTiyin = GeneratedColumn<int>(
    'received_tiyin',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changeTiyinMeta = const VerificationMeta(
    'changeTiyin',
  );
  @override
  late final GeneratedColumn<int> changeTiyin = GeneratedColumn<int>(
    'change_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    method,
    amountTiyin,
    receivedTiyin,
    changeTiyin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalePayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount_tiyin')) {
      context.handle(
        _amountTiyinMeta,
        amountTiyin.isAcceptableOrUnknown(
          data['amount_tiyin']!,
          _amountTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountTiyinMeta);
    }
    if (data.containsKey('received_tiyin')) {
      context.handle(
        _receivedTiyinMeta,
        receivedTiyin.isAcceptableOrUnknown(
          data['received_tiyin']!,
          _receivedTiyinMeta,
        ),
      );
    }
    if (data.containsKey('change_tiyin')) {
      context.handle(
        _changeTiyinMeta,
        changeTiyin.isAcceptableOrUnknown(
          data['change_tiyin']!,
          _changeTiyinMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalePayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalePayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      amountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_tiyin'],
      )!,
      receivedTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_tiyin'],
      ),
      changeTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_tiyin'],
      )!,
    );
  }

  @override
  $SalePaymentsTable createAlias(String alias) {
    return $SalePaymentsTable(attachedDatabase, alias);
  }
}

class SalePayment extends DataClass implements Insertable<SalePayment> {
  final String id;
  final String saleId;

  /// `cash` / `card` / `debt`.
  final String method;
  final int amountTiyin;

  /// Naqd: olingan pul; karta/nasiya — `null`.
  final int? receivedTiyin;
  final int changeTiyin;
  const SalePayment({
    required this.id,
    required this.saleId,
    required this.method,
    required this.amountTiyin,
    this.receivedTiyin,
    required this.changeTiyin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['method'] = Variable<String>(method);
    map['amount_tiyin'] = Variable<int>(amountTiyin);
    if (!nullToAbsent || receivedTiyin != null) {
      map['received_tiyin'] = Variable<int>(receivedTiyin);
    }
    map['change_tiyin'] = Variable<int>(changeTiyin);
    return map;
  }

  SalePaymentsCompanion toCompanion(bool nullToAbsent) {
    return SalePaymentsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      method: Value(method),
      amountTiyin: Value(amountTiyin),
      receivedTiyin: receivedTiyin == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedTiyin),
      changeTiyin: Value(changeTiyin),
    );
  }

  factory SalePayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalePayment(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      method: serializer.fromJson<String>(json['method']),
      amountTiyin: serializer.fromJson<int>(json['amountTiyin']),
      receivedTiyin: serializer.fromJson<int?>(json['receivedTiyin']),
      changeTiyin: serializer.fromJson<int>(json['changeTiyin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'method': serializer.toJson<String>(method),
      'amountTiyin': serializer.toJson<int>(amountTiyin),
      'receivedTiyin': serializer.toJson<int?>(receivedTiyin),
      'changeTiyin': serializer.toJson<int>(changeTiyin),
    };
  }

  SalePayment copyWith({
    String? id,
    String? saleId,
    String? method,
    int? amountTiyin,
    Value<int?> receivedTiyin = const Value.absent(),
    int? changeTiyin,
  }) => SalePayment(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    method: method ?? this.method,
    amountTiyin: amountTiyin ?? this.amountTiyin,
    receivedTiyin: receivedTiyin.present
        ? receivedTiyin.value
        : this.receivedTiyin,
    changeTiyin: changeTiyin ?? this.changeTiyin,
  );
  SalePayment copyWithCompanion(SalePaymentsCompanion data) {
    return SalePayment(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      method: data.method.present ? data.method.value : this.method,
      amountTiyin: data.amountTiyin.present
          ? data.amountTiyin.value
          : this.amountTiyin,
      receivedTiyin: data.receivedTiyin.present
          ? data.receivedTiyin.value
          : this.receivedTiyin,
      changeTiyin: data.changeTiyin.present
          ? data.changeTiyin.value
          : this.changeTiyin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalePayment(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amountTiyin: $amountTiyin, ')
          ..write('receivedTiyin: $receivedTiyin, ')
          ..write('changeTiyin: $changeTiyin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, saleId, method, amountTiyin, receivedTiyin, changeTiyin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalePayment &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.method == this.method &&
          other.amountTiyin == this.amountTiyin &&
          other.receivedTiyin == this.receivedTiyin &&
          other.changeTiyin == this.changeTiyin);
}

class SalePaymentsCompanion extends UpdateCompanion<SalePayment> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> method;
  final Value<int> amountTiyin;
  final Value<int?> receivedTiyin;
  final Value<int> changeTiyin;
  final Value<int> rowid;
  const SalePaymentsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.method = const Value.absent(),
    this.amountTiyin = const Value.absent(),
    this.receivedTiyin = const Value.absent(),
    this.changeTiyin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalePaymentsCompanion.insert({
    required String id,
    required String saleId,
    required String method,
    required int amountTiyin,
    this.receivedTiyin = const Value.absent(),
    this.changeTiyin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       method = Value(method),
       amountTiyin = Value(amountTiyin);
  static Insertable<SalePayment> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? method,
    Expression<int>? amountTiyin,
    Expression<int>? receivedTiyin,
    Expression<int>? changeTiyin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (method != null) 'method': method,
      if (amountTiyin != null) 'amount_tiyin': amountTiyin,
      if (receivedTiyin != null) 'received_tiyin': receivedTiyin,
      if (changeTiyin != null) 'change_tiyin': changeTiyin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalePaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String>? method,
    Value<int>? amountTiyin,
    Value<int?>? receivedTiyin,
    Value<int>? changeTiyin,
    Value<int>? rowid,
  }) {
    return SalePaymentsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      method: method ?? this.method,
      amountTiyin: amountTiyin ?? this.amountTiyin,
      receivedTiyin: receivedTiyin ?? this.receivedTiyin,
      changeTiyin: changeTiyin ?? this.changeTiyin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amountTiyin.present) {
      map['amount_tiyin'] = Variable<int>(amountTiyin.value);
    }
    if (receivedTiyin.present) {
      map['received_tiyin'] = Variable<int>(receivedTiyin.value);
    }
    if (changeTiyin.present) {
      map['change_tiyin'] = Variable<int>(changeTiyin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalePaymentsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amountTiyin: $amountTiyin, ')
          ..write('receivedTiyin: $receivedTiyin, ')
          ..write('changeTiyin: $changeTiyin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RefundsTable extends Refunds with TableInfo<$RefundsTable, Refund> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTiyinMeta = const VerificationMeta(
    'totalTiyin',
  );
  @override
  late final GeneratedColumn<int> totalTiyin = GeneratedColumn<int>(
    'total_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debtEntryIdMeta = const VerificationMeta(
    'debtEntryId',
  );
  @override
  late final GeneratedColumn<String> debtEntryId = GeneratedColumn<String>(
    'debt_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    shiftId,
    cashierId,
    approvedBy,
    reason,
    method,
    totalTiyin,
    debtEntryId,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refunds';
  @override
  VerificationContext validateIntegrity(
    Insertable<Refund> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('total_tiyin')) {
      context.handle(
        _totalTiyinMeta,
        totalTiyin.isAcceptableOrUnknown(data['total_tiyin']!, _totalTiyinMeta),
      );
    } else if (isInserting) {
      context.missing(_totalTiyinMeta);
    }
    if (data.containsKey('debt_entry_id')) {
      context.handle(
        _debtEntryIdMeta,
        debtEntryId.isAcceptableOrUnknown(
          data['debt_entry_id']!,
          _debtEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Refund map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Refund(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      totalTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_tiyin'],
      )!,
      debtEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_entry_id'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $RefundsTable createAlias(String alias) {
    return $RefundsTable(attachedDatabase, alias);
  }
}

class Refund extends DataClass implements Insertable<Refund> {
  final String id;
  final String saleId;
  final String shiftId;
  final String cashierId;
  final String? approvedBy;
  final String reason;

  /// `cash` / `debt`.
  final String method;
  final int totalTiyin;
  final String? debtEntryId;
  final DateTime at;
  const Refund({
    required this.id,
    required this.saleId,
    required this.shiftId,
    required this.cashierId,
    this.approvedBy,
    required this.reason,
    required this.method,
    required this.totalTiyin,
    this.debtEntryId,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['shift_id'] = Variable<String>(shiftId);
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    map['reason'] = Variable<String>(reason);
    map['method'] = Variable<String>(method);
    map['total_tiyin'] = Variable<int>(totalTiyin);
    if (!nullToAbsent || debtEntryId != null) {
      map['debt_entry_id'] = Variable<String>(debtEntryId);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  RefundsCompanion toCompanion(bool nullToAbsent) {
    return RefundsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      shiftId: Value(shiftId),
      cashierId: Value(cashierId),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
      reason: Value(reason),
      method: Value(method),
      totalTiyin: Value(totalTiyin),
      debtEntryId: debtEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(debtEntryId),
      at: Value(at),
    );
  }

  factory Refund.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Refund(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      reason: serializer.fromJson<String>(json['reason']),
      method: serializer.fromJson<String>(json['method']),
      totalTiyin: serializer.fromJson<int>(json['totalTiyin']),
      debtEntryId: serializer.fromJson<String?>(json['debtEntryId']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'shiftId': serializer.toJson<String>(shiftId),
      'cashierId': serializer.toJson<String>(cashierId),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'reason': serializer.toJson<String>(reason),
      'method': serializer.toJson<String>(method),
      'totalTiyin': serializer.toJson<int>(totalTiyin),
      'debtEntryId': serializer.toJson<String?>(debtEntryId),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  Refund copyWith({
    String? id,
    String? saleId,
    String? shiftId,
    String? cashierId,
    Value<String?> approvedBy = const Value.absent(),
    String? reason,
    String? method,
    int? totalTiyin,
    Value<String?> debtEntryId = const Value.absent(),
    DateTime? at,
  }) => Refund(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    shiftId: shiftId ?? this.shiftId,
    cashierId: cashierId ?? this.cashierId,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    reason: reason ?? this.reason,
    method: method ?? this.method,
    totalTiyin: totalTiyin ?? this.totalTiyin,
    debtEntryId: debtEntryId.present ? debtEntryId.value : this.debtEntryId,
    at: at ?? this.at,
  );
  Refund copyWithCompanion(RefundsCompanion data) {
    return Refund(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      reason: data.reason.present ? data.reason.value : this.reason,
      method: data.method.present ? data.method.value : this.method,
      totalTiyin: data.totalTiyin.present
          ? data.totalTiyin.value
          : this.totalTiyin,
      debtEntryId: data.debtEntryId.present
          ? data.debtEntryId.value
          : this.debtEntryId,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Refund(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('shiftId: $shiftId, ')
          ..write('cashierId: $cashierId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('reason: $reason, ')
          ..write('method: $method, ')
          ..write('totalTiyin: $totalTiyin, ')
          ..write('debtEntryId: $debtEntryId, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    shiftId,
    cashierId,
    approvedBy,
    reason,
    method,
    totalTiyin,
    debtEntryId,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Refund &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.shiftId == this.shiftId &&
          other.cashierId == this.cashierId &&
          other.approvedBy == this.approvedBy &&
          other.reason == this.reason &&
          other.method == this.method &&
          other.totalTiyin == this.totalTiyin &&
          other.debtEntryId == this.debtEntryId &&
          other.at == this.at);
}

class RefundsCompanion extends UpdateCompanion<Refund> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> shiftId;
  final Value<String> cashierId;
  final Value<String?> approvedBy;
  final Value<String> reason;
  final Value<String> method;
  final Value<int> totalTiyin;
  final Value<String?> debtEntryId;
  final Value<DateTime> at;
  final Value<int> rowid;
  const RefundsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.reason = const Value.absent(),
    this.method = const Value.absent(),
    this.totalTiyin = const Value.absent(),
    this.debtEntryId = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefundsCompanion.insert({
    required String id,
    required String saleId,
    required String shiftId,
    required String cashierId,
    this.approvedBy = const Value.absent(),
    this.reason = const Value.absent(),
    required String method,
    required int totalTiyin,
    this.debtEntryId = const Value.absent(),
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       shiftId = Value(shiftId),
       cashierId = Value(cashierId),
       method = Value(method),
       totalTiyin = Value(totalTiyin),
       at = Value(at);
  static Insertable<Refund> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? shiftId,
    Expression<String>? cashierId,
    Expression<String>? approvedBy,
    Expression<String>? reason,
    Expression<String>? method,
    Expression<int>? totalTiyin,
    Expression<String>? debtEntryId,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (shiftId != null) 'shift_id': shiftId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (reason != null) 'reason': reason,
      if (method != null) 'method': method,
      if (totalTiyin != null) 'total_tiyin': totalTiyin,
      if (debtEntryId != null) 'debt_entry_id': debtEntryId,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefundsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String>? shiftId,
    Value<String>? cashierId,
    Value<String?>? approvedBy,
    Value<String>? reason,
    Value<String>? method,
    Value<int>? totalTiyin,
    Value<String?>? debtEntryId,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return RefundsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      shiftId: shiftId ?? this.shiftId,
      cashierId: cashierId ?? this.cashierId,
      approvedBy: approvedBy ?? this.approvedBy,
      reason: reason ?? this.reason,
      method: method ?? this.method,
      totalTiyin: totalTiyin ?? this.totalTiyin,
      debtEntryId: debtEntryId ?? this.debtEntryId,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (totalTiyin.present) {
      map['total_tiyin'] = Variable<int>(totalTiyin.value);
    }
    if (debtEntryId.present) {
      map['debt_entry_id'] = Variable<String>(debtEntryId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('shiftId: $shiftId, ')
          ..write('cashierId: $cashierId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('reason: $reason, ')
          ..write('method: $method, ')
          ..write('totalTiyin: $totalTiyin, ')
          ..write('debtEntryId: $debtEntryId, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RefundItemsTable extends RefundItems
    with TableInfo<$RefundItemsTable, RefundItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refundIdMeta = const VerificationMeta(
    'refundId',
  );
  @override
  late final GeneratedColumn<String> refundId = GeneratedColumn<String>(
    'refund_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES refunds (id)',
    ),
  );
  static const VerificationMeta _saleItemIdMeta = const VerificationMeta(
    'saleItemId',
  );
  @override
  late final GeneratedColumn<String> saleItemId = GeneratedColumn<String>(
    'sale_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTiyinMeta = const VerificationMeta(
    'totalTiyin',
  );
  @override
  late final GeneratedColumn<int> totalTiyin = GeneratedColumn<int>(
    'total_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    refundId,
    saleItemId,
    qtyMilli,
    totalTiyin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refund_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RefundItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('refund_id')) {
      context.handle(
        _refundIdMeta,
        refundId.isAcceptableOrUnknown(data['refund_id']!, _refundIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refundIdMeta);
    }
    if (data.containsKey('sale_item_id')) {
      context.handle(
        _saleItemIdMeta,
        saleItemId.isAcceptableOrUnknown(
          data['sale_item_id']!,
          _saleItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleItemIdMeta);
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('total_tiyin')) {
      context.handle(
        _totalTiyinMeta,
        totalTiyin.isAcceptableOrUnknown(data['total_tiyin']!, _totalTiyinMeta),
      );
    } else if (isInserting) {
      context.missing(_totalTiyinMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefundItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefundItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      refundId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_id'],
      )!,
      saleItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_item_id'],
      )!,
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      totalTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_tiyin'],
      )!,
    );
  }

  @override
  $RefundItemsTable createAlias(String alias) {
    return $RefundItemsTable(attachedDatabase, alias);
  }
}

class RefundItem extends DataClass implements Insertable<RefundItem> {
  final String id;
  final String refundId;
  final String saleItemId;
  final int qtyMilli;
  final int totalTiyin;
  const RefundItem({
    required this.id,
    required this.refundId,
    required this.saleItemId,
    required this.qtyMilli,
    required this.totalTiyin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['refund_id'] = Variable<String>(refundId);
    map['sale_item_id'] = Variable<String>(saleItemId);
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['total_tiyin'] = Variable<int>(totalTiyin);
    return map;
  }

  RefundItemsCompanion toCompanion(bool nullToAbsent) {
    return RefundItemsCompanion(
      id: Value(id),
      refundId: Value(refundId),
      saleItemId: Value(saleItemId),
      qtyMilli: Value(qtyMilli),
      totalTiyin: Value(totalTiyin),
    );
  }

  factory RefundItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefundItem(
      id: serializer.fromJson<String>(json['id']),
      refundId: serializer.fromJson<String>(json['refundId']),
      saleItemId: serializer.fromJson<String>(json['saleItemId']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      totalTiyin: serializer.fromJson<int>(json['totalTiyin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'refundId': serializer.toJson<String>(refundId),
      'saleItemId': serializer.toJson<String>(saleItemId),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'totalTiyin': serializer.toJson<int>(totalTiyin),
    };
  }

  RefundItem copyWith({
    String? id,
    String? refundId,
    String? saleItemId,
    int? qtyMilli,
    int? totalTiyin,
  }) => RefundItem(
    id: id ?? this.id,
    refundId: refundId ?? this.refundId,
    saleItemId: saleItemId ?? this.saleItemId,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    totalTiyin: totalTiyin ?? this.totalTiyin,
  );
  RefundItem copyWithCompanion(RefundItemsCompanion data) {
    return RefundItem(
      id: data.id.present ? data.id.value : this.id,
      refundId: data.refundId.present ? data.refundId.value : this.refundId,
      saleItemId: data.saleItemId.present
          ? data.saleItemId.value
          : this.saleItemId,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      totalTiyin: data.totalTiyin.present
          ? data.totalTiyin.value
          : this.totalTiyin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefundItem(')
          ..write('id: $id, ')
          ..write('refundId: $refundId, ')
          ..write('saleItemId: $saleItemId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('totalTiyin: $totalTiyin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, refundId, saleItemId, qtyMilli, totalTiyin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefundItem &&
          other.id == this.id &&
          other.refundId == this.refundId &&
          other.saleItemId == this.saleItemId &&
          other.qtyMilli == this.qtyMilli &&
          other.totalTiyin == this.totalTiyin);
}

class RefundItemsCompanion extends UpdateCompanion<RefundItem> {
  final Value<String> id;
  final Value<String> refundId;
  final Value<String> saleItemId;
  final Value<int> qtyMilli;
  final Value<int> totalTiyin;
  final Value<int> rowid;
  const RefundItemsCompanion({
    this.id = const Value.absent(),
    this.refundId = const Value.absent(),
    this.saleItemId = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.totalTiyin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefundItemsCompanion.insert({
    required String id,
    required String refundId,
    required String saleItemId,
    required int qtyMilli,
    required int totalTiyin,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       refundId = Value(refundId),
       saleItemId = Value(saleItemId),
       qtyMilli = Value(qtyMilli),
       totalTiyin = Value(totalTiyin);
  static Insertable<RefundItem> custom({
    Expression<String>? id,
    Expression<String>? refundId,
    Expression<String>? saleItemId,
    Expression<int>? qtyMilli,
    Expression<int>? totalTiyin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (refundId != null) 'refund_id': refundId,
      if (saleItemId != null) 'sale_item_id': saleItemId,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (totalTiyin != null) 'total_tiyin': totalTiyin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefundItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? refundId,
    Value<String>? saleItemId,
    Value<int>? qtyMilli,
    Value<int>? totalTiyin,
    Value<int>? rowid,
  }) {
    return RefundItemsCompanion(
      id: id ?? this.id,
      refundId: refundId ?? this.refundId,
      saleItemId: saleItemId ?? this.saleItemId,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      totalTiyin: totalTiyin ?? this.totalTiyin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (refundId.present) {
      map['refund_id'] = Variable<String>(refundId.value);
    }
    if (saleItemId.present) {
      map['sale_item_id'] = Variable<String>(saleItemId.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (totalTiyin.present) {
      map['total_tiyin'] = Variable<int>(totalTiyin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundItemsCompanion(')
          ..write('id: $id, ')
          ..write('refundId: $refundId, ')
          ..write('saleItemId: $saleItemId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('totalTiyin: $totalTiyin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashMovementsTable extends CashMovements
    with TableInfo<$CashMovementsTable, CashMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountTiyinMeta = const VerificationMeta(
    'amountTiyin',
  );
  @override
  late final GeneratedColumn<int> amountTiyin = GeneratedColumn<int>(
    'amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _byUserIdMeta = const VerificationMeta(
    'byUserId',
  );
  @override
  late final GeneratedColumn<String> byUserId = GeneratedColumn<String>(
    'by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shiftId,
    type,
    amountTiyin,
    reason,
    byUserId,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_tiyin')) {
      context.handle(
        _amountTiyinMeta,
        amountTiyin.isAcceptableOrUnknown(
          data['amount_tiyin']!,
          _amountTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountTiyinMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('by_user_id')) {
      context.handle(
        _byUserIdMeta,
        byUserId.isAcceptableOrUnknown(data['by_user_id']!, _byUserIdMeta),
      );
    } else if (isInserting) {
      context.missing(_byUserIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_tiyin'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      byUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}by_user_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $CashMovementsTable createAlias(String alias) {
    return $CashMovementsTable(attachedDatabase, alias);
  }
}

class CashMovement extends DataClass implements Insertable<CashMovement> {
  final String id;
  final String shiftId;

  /// `in` / `out`.
  final String type;
  final int amountTiyin;
  final String reason;
  final String byUserId;
  final DateTime at;
  const CashMovement({
    required this.id,
    required this.shiftId,
    required this.type,
    required this.amountTiyin,
    required this.reason,
    required this.byUserId,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shift_id'] = Variable<String>(shiftId);
    map['type'] = Variable<String>(type);
    map['amount_tiyin'] = Variable<int>(amountTiyin);
    map['reason'] = Variable<String>(reason);
    map['by_user_id'] = Variable<String>(byUserId);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  CashMovementsCompanion toCompanion(bool nullToAbsent) {
    return CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: Value(type),
      amountTiyin: Value(amountTiyin),
      reason: Value(reason),
      byUserId: Value(byUserId),
      at: Value(at),
    );
  }

  factory CashMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashMovement(
      id: serializer.fromJson<String>(json['id']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      type: serializer.fromJson<String>(json['type']),
      amountTiyin: serializer.fromJson<int>(json['amountTiyin']),
      reason: serializer.fromJson<String>(json['reason']),
      byUserId: serializer.fromJson<String>(json['byUserId']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shiftId': serializer.toJson<String>(shiftId),
      'type': serializer.toJson<String>(type),
      'amountTiyin': serializer.toJson<int>(amountTiyin),
      'reason': serializer.toJson<String>(reason),
      'byUserId': serializer.toJson<String>(byUserId),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  CashMovement copyWith({
    String? id,
    String? shiftId,
    String? type,
    int? amountTiyin,
    String? reason,
    String? byUserId,
    DateTime? at,
  }) => CashMovement(
    id: id ?? this.id,
    shiftId: shiftId ?? this.shiftId,
    type: type ?? this.type,
    amountTiyin: amountTiyin ?? this.amountTiyin,
    reason: reason ?? this.reason,
    byUserId: byUserId ?? this.byUserId,
    at: at ?? this.at,
  );
  CashMovement copyWithCompanion(CashMovementsCompanion data) {
    return CashMovement(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      type: data.type.present ? data.type.value : this.type,
      amountTiyin: data.amountTiyin.present
          ? data.amountTiyin.value
          : this.amountTiyin,
      reason: data.reason.present ? data.reason.value : this.reason,
      byUserId: data.byUserId.present ? data.byUserId.value : this.byUserId,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashMovement(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('type: $type, ')
          ..write('amountTiyin: $amountTiyin, ')
          ..write('reason: $reason, ')
          ..write('byUserId: $byUserId, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shiftId, type, amountTiyin, reason, byUserId, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashMovement &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.type == this.type &&
          other.amountTiyin == this.amountTiyin &&
          other.reason == this.reason &&
          other.byUserId == this.byUserId &&
          other.at == this.at);
}

class CashMovementsCompanion extends UpdateCompanion<CashMovement> {
  final Value<String> id;
  final Value<String> shiftId;
  final Value<String> type;
  final Value<int> amountTiyin;
  final Value<String> reason;
  final Value<String> byUserId;
  final Value<DateTime> at;
  final Value<int> rowid;
  const CashMovementsCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.type = const Value.absent(),
    this.amountTiyin = const Value.absent(),
    this.reason = const Value.absent(),
    this.byUserId = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashMovementsCompanion.insert({
    required String id,
    required String shiftId,
    required String type,
    required int amountTiyin,
    this.reason = const Value.absent(),
    required String byUserId,
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shiftId = Value(shiftId),
       type = Value(type),
       amountTiyin = Value(amountTiyin),
       byUserId = Value(byUserId),
       at = Value(at);
  static Insertable<CashMovement> custom({
    Expression<String>? id,
    Expression<String>? shiftId,
    Expression<String>? type,
    Expression<int>? amountTiyin,
    Expression<String>? reason,
    Expression<String>? byUserId,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (type != null) 'type': type,
      if (amountTiyin != null) 'amount_tiyin': amountTiyin,
      if (reason != null) 'reason': reason,
      if (byUserId != null) 'by_user_id': byUserId,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? shiftId,
    Value<String>? type,
    Value<int>? amountTiyin,
    Value<String>? reason,
    Value<String>? byUserId,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return CashMovementsCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      type: type ?? this.type,
      amountTiyin: amountTiyin ?? this.amountTiyin,
      reason: reason ?? this.reason,
      byUserId: byUserId ?? this.byUserId,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountTiyin.present) {
      map['amount_tiyin'] = Variable<int>(amountTiyin.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (byUserId.present) {
      map['by_user_id'] = Variable<String>(byUserId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashMovementsCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('type: $type, ')
          ..write('amountTiyin: $amountTiyin, ')
          ..write('reason: $reason, ')
          ..write('byUserId: $byUserId, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockReceiptsTable extends StockReceipts
    with TableInfo<$StockReceiptsTable, StockReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _totalCostTiyinMeta = const VerificationMeta(
    'totalCostTiyin',
  );
  @override
  late final GeneratedColumn<int> totalCostTiyin = GeneratedColumn<int>(
    'total_cost_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<DateTime> postedAt = GeneratedColumn<DateTime>(
    'posted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postedByMeta = const VerificationMeta(
    'postedBy',
  );
  @override
  late final GeneratedColumn<String> postedBy = GeneratedColumn<String>(
    'posted_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctsIdMeta = const VerificationMeta(
    'correctsId',
  );
  @override
  late final GeneratedColumn<String> correctsId = GeneratedColumn<String>(
    'corrects_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reversesIdMeta = const VerificationMeta(
    'reversesId',
  );
  @override
  late final GeneratedColumn<String> reversesId = GeneratedColumn<String>(
    'reverses_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supplierId,
    storeId,
    number,
    status,
    totalCostTiyin,
    note,
    createdAt,
    postedAt,
    postedBy,
    correctsId,
    reversesId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockReceipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('total_cost_tiyin')) {
      context.handle(
        _totalCostTiyinMeta,
        totalCostTiyin.isAcceptableOrUnknown(
          data['total_cost_tiyin']!,
          _totalCostTiyinMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
      );
    }
    if (data.containsKey('posted_by')) {
      context.handle(
        _postedByMeta,
        postedBy.isAcceptableOrUnknown(data['posted_by']!, _postedByMeta),
      );
    }
    if (data.containsKey('corrects_id')) {
      context.handle(
        _correctsIdMeta,
        correctsId.isAcceptableOrUnknown(data['corrects_id']!, _correctsIdMeta),
      );
    }
    if (data.containsKey('reverses_id')) {
      context.handle(
        _reversesIdMeta,
        reversesId.isAcceptableOrUnknown(data['reverses_id']!, _reversesIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockReceipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalCostTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cost_tiyin'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}posted_at'],
      ),
      postedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}posted_by'],
      ),
      correctsId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrects_id'],
      ),
      reversesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reverses_id'],
      ),
    );
  }

  @override
  $StockReceiptsTable createAlias(String alias) {
    return $StockReceiptsTable(attachedDatabase, alias);
  }
}

class StockReceipt extends DataClass implements Insertable<StockReceipt> {
  final String id;
  final String? supplierId;
  final String? storeId;

  /// Tartib raqami — server beradi (pull'dan keyin).
  final int? number;

  /// `draft` / `posted`.
  final String status;
  final int totalCostTiyin;
  final String note;
  final DateTime createdAt;
  final DateTime? postedAt;
  final String? postedBy;

  /// Tuzatish (T-102): bu kirim qaysi kirimning yangi versiyasi. Asl kirim
  /// o'zgarmaydi — "tuzatilgan" holati shu ustundan topiladi.
  final String? correctsId;

  /// Teskari yozuv: qaysi kirimni bekor qiladi (manfiy qatorlar).
  final String? reversesId;
  const StockReceipt({
    required this.id,
    this.supplierId,
    this.storeId,
    this.number,
    required this.status,
    required this.totalCostTiyin,
    required this.note,
    required this.createdAt,
    this.postedAt,
    this.postedBy,
    this.correctsId,
    this.reversesId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<String>(supplierId);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    map['status'] = Variable<String>(status);
    map['total_cost_tiyin'] = Variable<int>(totalCostTiyin);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<DateTime>(postedAt);
    }
    if (!nullToAbsent || postedBy != null) {
      map['posted_by'] = Variable<String>(postedBy);
    }
    if (!nullToAbsent || correctsId != null) {
      map['corrects_id'] = Variable<String>(correctsId);
    }
    if (!nullToAbsent || reversesId != null) {
      map['reverses_id'] = Variable<String>(reversesId);
    }
    return map;
  }

  StockReceiptsCompanion toCompanion(bool nullToAbsent) {
    return StockReceiptsCompanion(
      id: Value(id),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      status: Value(status),
      totalCostTiyin: Value(totalCostTiyin),
      note: Value(note),
      createdAt: Value(createdAt),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      postedBy: postedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(postedBy),
      correctsId: correctsId == null && nullToAbsent
          ? const Value.absent()
          : Value(correctsId),
      reversesId: reversesId == null && nullToAbsent
          ? const Value.absent()
          : Value(reversesId),
    );
  }

  factory StockReceipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockReceipt(
      id: serializer.fromJson<String>(json['id']),
      supplierId: serializer.fromJson<String?>(json['supplierId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      number: serializer.fromJson<int?>(json['number']),
      status: serializer.fromJson<String>(json['status']),
      totalCostTiyin: serializer.fromJson<int>(json['totalCostTiyin']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      postedAt: serializer.fromJson<DateTime?>(json['postedAt']),
      postedBy: serializer.fromJson<String?>(json['postedBy']),
      correctsId: serializer.fromJson<String?>(json['correctsId']),
      reversesId: serializer.fromJson<String?>(json['reversesId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'supplierId': serializer.toJson<String?>(supplierId),
      'storeId': serializer.toJson<String?>(storeId),
      'number': serializer.toJson<int?>(number),
      'status': serializer.toJson<String>(status),
      'totalCostTiyin': serializer.toJson<int>(totalCostTiyin),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'postedAt': serializer.toJson<DateTime?>(postedAt),
      'postedBy': serializer.toJson<String?>(postedBy),
      'correctsId': serializer.toJson<String?>(correctsId),
      'reversesId': serializer.toJson<String?>(reversesId),
    };
  }

  StockReceipt copyWith({
    String? id,
    Value<String?> supplierId = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    Value<int?> number = const Value.absent(),
    String? status,
    int? totalCostTiyin,
    String? note,
    DateTime? createdAt,
    Value<DateTime?> postedAt = const Value.absent(),
    Value<String?> postedBy = const Value.absent(),
    Value<String?> correctsId = const Value.absent(),
    Value<String?> reversesId = const Value.absent(),
  }) => StockReceipt(
    id: id ?? this.id,
    supplierId: supplierId.present ? supplierId.value : this.supplierId,
    storeId: storeId.present ? storeId.value : this.storeId,
    number: number.present ? number.value : this.number,
    status: status ?? this.status,
    totalCostTiyin: totalCostTiyin ?? this.totalCostTiyin,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    postedAt: postedAt.present ? postedAt.value : this.postedAt,
    postedBy: postedBy.present ? postedBy.value : this.postedBy,
    correctsId: correctsId.present ? correctsId.value : this.correctsId,
    reversesId: reversesId.present ? reversesId.value : this.reversesId,
  );
  StockReceipt copyWithCompanion(StockReceiptsCompanion data) {
    return StockReceipt(
      id: data.id.present ? data.id.value : this.id,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      number: data.number.present ? data.number.value : this.number,
      status: data.status.present ? data.status.value : this.status,
      totalCostTiyin: data.totalCostTiyin.present
          ? data.totalCostTiyin.value
          : this.totalCostTiyin,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      postedBy: data.postedBy.present ? data.postedBy.value : this.postedBy,
      correctsId: data.correctsId.present
          ? data.correctsId.value
          : this.correctsId,
      reversesId: data.reversesId.present
          ? data.reversesId.value
          : this.reversesId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockReceipt(')
          ..write('id: $id, ')
          ..write('supplierId: $supplierId, ')
          ..write('storeId: $storeId, ')
          ..write('number: $number, ')
          ..write('status: $status, ')
          ..write('totalCostTiyin: $totalCostTiyin, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('postedAt: $postedAt, ')
          ..write('postedBy: $postedBy, ')
          ..write('correctsId: $correctsId, ')
          ..write('reversesId: $reversesId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supplierId,
    storeId,
    number,
    status,
    totalCostTiyin,
    note,
    createdAt,
    postedAt,
    postedBy,
    correctsId,
    reversesId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockReceipt &&
          other.id == this.id &&
          other.supplierId == this.supplierId &&
          other.storeId == this.storeId &&
          other.number == this.number &&
          other.status == this.status &&
          other.totalCostTiyin == this.totalCostTiyin &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.postedAt == this.postedAt &&
          other.postedBy == this.postedBy &&
          other.correctsId == this.correctsId &&
          other.reversesId == this.reversesId);
}

class StockReceiptsCompanion extends UpdateCompanion<StockReceipt> {
  final Value<String> id;
  final Value<String?> supplierId;
  final Value<String?> storeId;
  final Value<int?> number;
  final Value<String> status;
  final Value<int> totalCostTiyin;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime?> postedAt;
  final Value<String?> postedBy;
  final Value<String?> correctsId;
  final Value<String?> reversesId;
  final Value<int> rowid;
  const StockReceiptsCompanion({
    this.id = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.number = const Value.absent(),
    this.status = const Value.absent(),
    this.totalCostTiyin = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.postedBy = const Value.absent(),
    this.correctsId = const Value.absent(),
    this.reversesId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockReceiptsCompanion.insert({
    required String id,
    this.supplierId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.number = const Value.absent(),
    this.status = const Value.absent(),
    this.totalCostTiyin = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.postedAt = const Value.absent(),
    this.postedBy = const Value.absent(),
    this.correctsId = const Value.absent(),
    this.reversesId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<StockReceipt> custom({
    Expression<String>? id,
    Expression<String>? supplierId,
    Expression<String>? storeId,
    Expression<int>? number,
    Expression<String>? status,
    Expression<int>? totalCostTiyin,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? postedAt,
    Expression<String>? postedBy,
    Expression<String>? correctsId,
    Expression<String>? reversesId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supplierId != null) 'supplier_id': supplierId,
      if (storeId != null) 'store_id': storeId,
      if (number != null) 'number': number,
      if (status != null) 'status': status,
      if (totalCostTiyin != null) 'total_cost_tiyin': totalCostTiyin,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (postedAt != null) 'posted_at': postedAt,
      if (postedBy != null) 'posted_by': postedBy,
      if (correctsId != null) 'corrects_id': correctsId,
      if (reversesId != null) 'reverses_id': reversesId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockReceiptsCompanion copyWith({
    Value<String>? id,
    Value<String?>? supplierId,
    Value<String?>? storeId,
    Value<int?>? number,
    Value<String>? status,
    Value<int>? totalCostTiyin,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime?>? postedAt,
    Value<String?>? postedBy,
    Value<String?>? correctsId,
    Value<String?>? reversesId,
    Value<int>? rowid,
  }) {
    return StockReceiptsCompanion(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      storeId: storeId ?? this.storeId,
      number: number ?? this.number,
      status: status ?? this.status,
      totalCostTiyin: totalCostTiyin ?? this.totalCostTiyin,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      postedAt: postedAt ?? this.postedAt,
      postedBy: postedBy ?? this.postedBy,
      correctsId: correctsId ?? this.correctsId,
      reversesId: reversesId ?? this.reversesId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalCostTiyin.present) {
      map['total_cost_tiyin'] = Variable<int>(totalCostTiyin.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<DateTime>(postedAt.value);
    }
    if (postedBy.present) {
      map['posted_by'] = Variable<String>(postedBy.value);
    }
    if (correctsId.present) {
      map['corrects_id'] = Variable<String>(correctsId.value);
    }
    if (reversesId.present) {
      map['reverses_id'] = Variable<String>(reversesId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('supplierId: $supplierId, ')
          ..write('storeId: $storeId, ')
          ..write('number: $number, ')
          ..write('status: $status, ')
          ..write('totalCostTiyin: $totalCostTiyin, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('postedAt: $postedAt, ')
          ..write('postedBy: $postedBy, ')
          ..write('correctsId: $correctsId, ')
          ..write('reversesId: $reversesId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockReceiptItemsTable extends StockReceiptItems
    with TableInfo<$StockReceiptItemsTable, StockReceiptItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockReceiptItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stock_receipts (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceTiyinMeta = const VerificationMeta(
    'costPriceTiyin',
  );
  @override
  late final GeneratedColumn<int> costPriceTiyin = GeneratedColumn<int>(
    'cost_price_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newSellPriceTiyinMeta = const VerificationMeta(
    'newSellPriceTiyin',
  );
  @override
  late final GeneratedColumn<int> newSellPriceTiyin = GeneratedColumn<int>(
    'new_sell_price_tiyin',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    position,
    productId,
    qtyMilli,
    costPriceTiyin,
    newSellPriceTiyin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_receipt_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockReceiptItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('cost_price_tiyin')) {
      context.handle(
        _costPriceTiyinMeta,
        costPriceTiyin.isAcceptableOrUnknown(
          data['cost_price_tiyin']!,
          _costPriceTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costPriceTiyinMeta);
    }
    if (data.containsKey('new_sell_price_tiyin')) {
      context.handle(
        _newSellPriceTiyinMeta,
        newSellPriceTiyin.isAcceptableOrUnknown(
          data['new_sell_price_tiyin']!,
          _newSellPriceTiyinMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockReceiptItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockReceiptItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      costPriceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_price_tiyin'],
      )!,
      newSellPriceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_sell_price_tiyin'],
      ),
    );
  }

  @override
  $StockReceiptItemsTable createAlias(String alias) {
    return $StockReceiptItemsTable(attachedDatabase, alias);
  }
}

class StockReceiptItem extends DataClass
    implements Insertable<StockReceiptItem> {
  final String id;
  final String receiptId;
  final int position;
  final String productId;
  final int qtyMilli;
  final int costPriceTiyin;
  final int? newSellPriceTiyin;
  const StockReceiptItem({
    required this.id,
    required this.receiptId,
    required this.position,
    required this.productId,
    required this.qtyMilli,
    required this.costPriceTiyin,
    this.newSellPriceTiyin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['position'] = Variable<int>(position);
    map['product_id'] = Variable<String>(productId);
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['cost_price_tiyin'] = Variable<int>(costPriceTiyin);
    if (!nullToAbsent || newSellPriceTiyin != null) {
      map['new_sell_price_tiyin'] = Variable<int>(newSellPriceTiyin);
    }
    return map;
  }

  StockReceiptItemsCompanion toCompanion(bool nullToAbsent) {
    return StockReceiptItemsCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      position: Value(position),
      productId: Value(productId),
      qtyMilli: Value(qtyMilli),
      costPriceTiyin: Value(costPriceTiyin),
      newSellPriceTiyin: newSellPriceTiyin == null && nullToAbsent
          ? const Value.absent()
          : Value(newSellPriceTiyin),
    );
  }

  factory StockReceiptItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockReceiptItem(
      id: serializer.fromJson<String>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      position: serializer.fromJson<int>(json['position']),
      productId: serializer.fromJson<String>(json['productId']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      costPriceTiyin: serializer.fromJson<int>(json['costPriceTiyin']),
      newSellPriceTiyin: serializer.fromJson<int?>(json['newSellPriceTiyin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'position': serializer.toJson<int>(position),
      'productId': serializer.toJson<String>(productId),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'costPriceTiyin': serializer.toJson<int>(costPriceTiyin),
      'newSellPriceTiyin': serializer.toJson<int?>(newSellPriceTiyin),
    };
  }

  StockReceiptItem copyWith({
    String? id,
    String? receiptId,
    int? position,
    String? productId,
    int? qtyMilli,
    int? costPriceTiyin,
    Value<int?> newSellPriceTiyin = const Value.absent(),
  }) => StockReceiptItem(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    position: position ?? this.position,
    productId: productId ?? this.productId,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    costPriceTiyin: costPriceTiyin ?? this.costPriceTiyin,
    newSellPriceTiyin: newSellPriceTiyin.present
        ? newSellPriceTiyin.value
        : this.newSellPriceTiyin,
  );
  StockReceiptItem copyWithCompanion(StockReceiptItemsCompanion data) {
    return StockReceiptItem(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      position: data.position.present ? data.position.value : this.position,
      productId: data.productId.present ? data.productId.value : this.productId,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      costPriceTiyin: data.costPriceTiyin.present
          ? data.costPriceTiyin.value
          : this.costPriceTiyin,
      newSellPriceTiyin: data.newSellPriceTiyin.present
          ? data.newSellPriceTiyin.value
          : this.newSellPriceTiyin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockReceiptItem(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('position: $position, ')
          ..write('productId: $productId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('costPriceTiyin: $costPriceTiyin, ')
          ..write('newSellPriceTiyin: $newSellPriceTiyin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    receiptId,
    position,
    productId,
    qtyMilli,
    costPriceTiyin,
    newSellPriceTiyin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockReceiptItem &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.position == this.position &&
          other.productId == this.productId &&
          other.qtyMilli == this.qtyMilli &&
          other.costPriceTiyin == this.costPriceTiyin &&
          other.newSellPriceTiyin == this.newSellPriceTiyin);
}

class StockReceiptItemsCompanion extends UpdateCompanion<StockReceiptItem> {
  final Value<String> id;
  final Value<String> receiptId;
  final Value<int> position;
  final Value<String> productId;
  final Value<int> qtyMilli;
  final Value<int> costPriceTiyin;
  final Value<int?> newSellPriceTiyin;
  final Value<int> rowid;
  const StockReceiptItemsCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.position = const Value.absent(),
    this.productId = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.costPriceTiyin = const Value.absent(),
    this.newSellPriceTiyin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockReceiptItemsCompanion.insert({
    required String id,
    required String receiptId,
    required int position,
    required String productId,
    required int qtyMilli,
    required int costPriceTiyin,
    this.newSellPriceTiyin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptId = Value(receiptId),
       position = Value(position),
       productId = Value(productId),
       qtyMilli = Value(qtyMilli),
       costPriceTiyin = Value(costPriceTiyin);
  static Insertable<StockReceiptItem> custom({
    Expression<String>? id,
    Expression<String>? receiptId,
    Expression<int>? position,
    Expression<String>? productId,
    Expression<int>? qtyMilli,
    Expression<int>? costPriceTiyin,
    Expression<int>? newSellPriceTiyin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (position != null) 'position': position,
      if (productId != null) 'product_id': productId,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (costPriceTiyin != null) 'cost_price_tiyin': costPriceTiyin,
      if (newSellPriceTiyin != null) 'new_sell_price_tiyin': newSellPriceTiyin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockReceiptItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptId,
    Value<int>? position,
    Value<String>? productId,
    Value<int>? qtyMilli,
    Value<int>? costPriceTiyin,
    Value<int?>? newSellPriceTiyin,
    Value<int>? rowid,
  }) {
    return StockReceiptItemsCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      position: position ?? this.position,
      productId: productId ?? this.productId,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      costPriceTiyin: costPriceTiyin ?? this.costPriceTiyin,
      newSellPriceTiyin: newSellPriceTiyin ?? this.newSellPriceTiyin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (costPriceTiyin.present) {
      map['cost_price_tiyin'] = Variable<int>(costPriceTiyin.value);
    }
    if (newSellPriceTiyin.present) {
      map['new_sell_price_tiyin'] = Variable<int>(newSellPriceTiyin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockReceiptItemsCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('position: $position, ')
          ..write('productId: $productId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('costPriceTiyin: $costPriceTiyin, ')
          ..write('newSellPriceTiyin: $newSellPriceTiyin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryCountsTable extends InventoryCounts
    with TableInfo<$InventoryCountsTable, InventoryCount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryCountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('all'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<DateTime> postedAt = GeneratedColumn<DateTime>(
    'posted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postedByMeta = const VerificationMeta(
    'postedBy',
  );
  @override
  late final GeneratedColumn<String> postedBy = GeneratedColumn<String>(
    'posted_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    status,
    scope,
    categoryId,
    note,
    createdAt,
    postedAt,
    postedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_counts';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryCount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
      );
    }
    if (data.containsKey('posted_by')) {
      context.handle(
        _postedByMeta,
        postedBy.isAcceptableOrUnknown(data['posted_by']!, _postedByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryCount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryCount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}posted_at'],
      ),
      postedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}posted_by'],
      ),
    );
  }

  @override
  $InventoryCountsTable createAlias(String alias) {
    return $InventoryCountsTable(attachedDatabase, alias);
  }
}

class InventoryCount extends DataClass implements Insertable<InventoryCount> {
  final String id;
  final String? storeId;

  /// `draft` / `posted`.
  final String status;

  /// `all` / `category`.
  final String scope;
  final String? categoryId;
  final String note;
  final DateTime createdAt;
  final DateTime? postedAt;
  final String? postedBy;
  const InventoryCount({
    required this.id,
    this.storeId,
    required this.status,
    required this.scope,
    this.categoryId,
    required this.note,
    required this.createdAt,
    this.postedAt,
    this.postedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['status'] = Variable<String>(status);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<DateTime>(postedAt);
    }
    if (!nullToAbsent || postedBy != null) {
      map['posted_by'] = Variable<String>(postedBy);
    }
    return map;
  }

  InventoryCountsCompanion toCompanion(bool nullToAbsent) {
    return InventoryCountsCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      status: Value(status),
      scope: Value(scope),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      note: Value(note),
      createdAt: Value(createdAt),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      postedBy: postedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(postedBy),
    );
  }

  factory InventoryCount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryCount(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      status: serializer.fromJson<String>(json['status']),
      scope: serializer.fromJson<String>(json['scope']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      postedAt: serializer.fromJson<DateTime?>(json['postedAt']),
      postedBy: serializer.fromJson<String?>(json['postedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String?>(storeId),
      'status': serializer.toJson<String>(status),
      'scope': serializer.toJson<String>(scope),
      'categoryId': serializer.toJson<String?>(categoryId),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'postedAt': serializer.toJson<DateTime?>(postedAt),
      'postedBy': serializer.toJson<String?>(postedBy),
    };
  }

  InventoryCount copyWith({
    String? id,
    Value<String?> storeId = const Value.absent(),
    String? status,
    String? scope,
    Value<String?> categoryId = const Value.absent(),
    String? note,
    DateTime? createdAt,
    Value<DateTime?> postedAt = const Value.absent(),
    Value<String?> postedBy = const Value.absent(),
  }) => InventoryCount(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    status: status ?? this.status,
    scope: scope ?? this.scope,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    postedAt: postedAt.present ? postedAt.value : this.postedAt,
    postedBy: postedBy.present ? postedBy.value : this.postedBy,
  );
  InventoryCount copyWithCompanion(InventoryCountsCompanion data) {
    return InventoryCount(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      status: data.status.present ? data.status.value : this.status,
      scope: data.scope.present ? data.scope.value : this.scope,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      postedBy: data.postedBy.present ? data.postedBy.value : this.postedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCount(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('status: $status, ')
          ..write('scope: $scope, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('postedAt: $postedAt, ')
          ..write('postedBy: $postedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    status,
    scope,
    categoryId,
    note,
    createdAt,
    postedAt,
    postedBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryCount &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.status == this.status &&
          other.scope == this.scope &&
          other.categoryId == this.categoryId &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.postedAt == this.postedAt &&
          other.postedBy == this.postedBy);
}

class InventoryCountsCompanion extends UpdateCompanion<InventoryCount> {
  final Value<String> id;
  final Value<String?> storeId;
  final Value<String> status;
  final Value<String> scope;
  final Value<String?> categoryId;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime?> postedAt;
  final Value<String?> postedBy;
  final Value<int> rowid;
  const InventoryCountsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.status = const Value.absent(),
    this.scope = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.postedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryCountsCompanion.insert({
    required String id,
    this.storeId = const Value.absent(),
    this.status = const Value.absent(),
    this.scope = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.postedAt = const Value.absent(),
    this.postedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<InventoryCount> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? status,
    Expression<String>? scope,
    Expression<String>? categoryId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? postedAt,
    Expression<String>? postedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (status != null) 'status': status,
      if (scope != null) 'scope': scope,
      if (categoryId != null) 'category_id': categoryId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (postedAt != null) 'posted_at': postedAt,
      if (postedBy != null) 'posted_by': postedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryCountsCompanion copyWith({
    Value<String>? id,
    Value<String?>? storeId,
    Value<String>? status,
    Value<String>? scope,
    Value<String?>? categoryId,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime?>? postedAt,
    Value<String?>? postedBy,
    Value<int>? rowid,
  }) {
    return InventoryCountsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      status: status ?? this.status,
      scope: scope ?? this.scope,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      postedAt: postedAt ?? this.postedAt,
      postedBy: postedBy ?? this.postedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<DateTime>(postedAt.value);
    }
    if (postedBy.present) {
      map['posted_by'] = Variable<String>(postedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCountsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('status: $status, ')
          ..write('scope: $scope, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('postedAt: $postedAt, ')
          ..write('postedBy: $postedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryCountItemsTable extends InventoryCountItems
    with TableInfo<$InventoryCountItemsTable, InventoryCountItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryCountItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countIdMeta = const VerificationMeta(
    'countId',
  );
  @override
  late final GeneratedColumn<String> countId = GeneratedColumn<String>(
    'count_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventory_counts (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedMilliMeta = const VerificationMeta(
    'expectedMilli',
  );
  @override
  late final GeneratedColumn<int> expectedMilli = GeneratedColumn<int>(
    'expected_milli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countedMilliMeta = const VerificationMeta(
    'countedMilli',
  );
  @override
  late final GeneratedColumn<int> countedMilli = GeneratedColumn<int>(
    'counted_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    countId,
    productId,
    expectedMilli,
    countedMilli,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_count_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryCountItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('count_id')) {
      context.handle(
        _countIdMeta,
        countId.isAcceptableOrUnknown(data['count_id']!, _countIdMeta),
      );
    } else if (isInserting) {
      context.missing(_countIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('expected_milli')) {
      context.handle(
        _expectedMilliMeta,
        expectedMilli.isAcceptableOrUnknown(
          data['expected_milli']!,
          _expectedMilliMeta,
        ),
      );
    }
    if (data.containsKey('counted_milli')) {
      context.handle(
        _countedMilliMeta,
        countedMilli.isAcceptableOrUnknown(
          data['counted_milli']!,
          _countedMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countedMilliMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryCountItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryCountItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      countId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}count_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      expectedMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_milli'],
      ),
      countedMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counted_milli'],
      )!,
    );
  }

  @override
  $InventoryCountItemsTable createAlias(String alias) {
    return $InventoryCountItemsTable(attachedDatabase, alias);
  }
}

class InventoryCountItem extends DataClass
    implements Insertable<InventoryCountItem> {
  final String id;
  final String countId;
  final String productId;

  /// Tasdiqlash paytidagi qoldiq; qoralamada `null`.
  final int? expectedMilli;
  final int countedMilli;
  const InventoryCountItem({
    required this.id,
    required this.countId,
    required this.productId,
    this.expectedMilli,
    required this.countedMilli,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['count_id'] = Variable<String>(countId);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || expectedMilli != null) {
      map['expected_milli'] = Variable<int>(expectedMilli);
    }
    map['counted_milli'] = Variable<int>(countedMilli);
    return map;
  }

  InventoryCountItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryCountItemsCompanion(
      id: Value(id),
      countId: Value(countId),
      productId: Value(productId),
      expectedMilli: expectedMilli == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedMilli),
      countedMilli: Value(countedMilli),
    );
  }

  factory InventoryCountItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryCountItem(
      id: serializer.fromJson<String>(json['id']),
      countId: serializer.fromJson<String>(json['countId']),
      productId: serializer.fromJson<String>(json['productId']),
      expectedMilli: serializer.fromJson<int?>(json['expectedMilli']),
      countedMilli: serializer.fromJson<int>(json['countedMilli']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'countId': serializer.toJson<String>(countId),
      'productId': serializer.toJson<String>(productId),
      'expectedMilli': serializer.toJson<int?>(expectedMilli),
      'countedMilli': serializer.toJson<int>(countedMilli),
    };
  }

  InventoryCountItem copyWith({
    String? id,
    String? countId,
    String? productId,
    Value<int?> expectedMilli = const Value.absent(),
    int? countedMilli,
  }) => InventoryCountItem(
    id: id ?? this.id,
    countId: countId ?? this.countId,
    productId: productId ?? this.productId,
    expectedMilli: expectedMilli.present
        ? expectedMilli.value
        : this.expectedMilli,
    countedMilli: countedMilli ?? this.countedMilli,
  );
  InventoryCountItem copyWithCompanion(InventoryCountItemsCompanion data) {
    return InventoryCountItem(
      id: data.id.present ? data.id.value : this.id,
      countId: data.countId.present ? data.countId.value : this.countId,
      productId: data.productId.present ? data.productId.value : this.productId,
      expectedMilli: data.expectedMilli.present
          ? data.expectedMilli.value
          : this.expectedMilli,
      countedMilli: data.countedMilli.present
          ? data.countedMilli.value
          : this.countedMilli,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCountItem(')
          ..write('id: $id, ')
          ..write('countId: $countId, ')
          ..write('productId: $productId, ')
          ..write('expectedMilli: $expectedMilli, ')
          ..write('countedMilli: $countedMilli')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, countId, productId, expectedMilli, countedMilli);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryCountItem &&
          other.id == this.id &&
          other.countId == this.countId &&
          other.productId == this.productId &&
          other.expectedMilli == this.expectedMilli &&
          other.countedMilli == this.countedMilli);
}

class InventoryCountItemsCompanion extends UpdateCompanion<InventoryCountItem> {
  final Value<String> id;
  final Value<String> countId;
  final Value<String> productId;
  final Value<int?> expectedMilli;
  final Value<int> countedMilli;
  final Value<int> rowid;
  const InventoryCountItemsCompanion({
    this.id = const Value.absent(),
    this.countId = const Value.absent(),
    this.productId = const Value.absent(),
    this.expectedMilli = const Value.absent(),
    this.countedMilli = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryCountItemsCompanion.insert({
    required String id,
    required String countId,
    required String productId,
    this.expectedMilli = const Value.absent(),
    required int countedMilli,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       countId = Value(countId),
       productId = Value(productId),
       countedMilli = Value(countedMilli);
  static Insertable<InventoryCountItem> custom({
    Expression<String>? id,
    Expression<String>? countId,
    Expression<String>? productId,
    Expression<int>? expectedMilli,
    Expression<int>? countedMilli,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (countId != null) 'count_id': countId,
      if (productId != null) 'product_id': productId,
      if (expectedMilli != null) 'expected_milli': expectedMilli,
      if (countedMilli != null) 'counted_milli': countedMilli,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryCountItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? countId,
    Value<String>? productId,
    Value<int?>? expectedMilli,
    Value<int>? countedMilli,
    Value<int>? rowid,
  }) {
    return InventoryCountItemsCompanion(
      id: id ?? this.id,
      countId: countId ?? this.countId,
      productId: productId ?? this.productId,
      expectedMilli: expectedMilli ?? this.expectedMilli,
      countedMilli: countedMilli ?? this.countedMilli,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (countId.present) {
      map['count_id'] = Variable<String>(countId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (expectedMilli.present) {
      map['expected_milli'] = Variable<int>(expectedMilli.value);
    }
    if (countedMilli.present) {
      map['counted_milli'] = Variable<int>(countedMilli.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCountItemsCompanion(')
          ..write('id: $id, ')
          ..write('countId: $countId, ')
          ..write('productId: $productId, ')
          ..write('expectedMilli: $expectedMilli, ')
          ..write('countedMilli: $countedMilli, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refTypeMeta = const VerificationMeta(
    'refType',
  );
  @override
  late final GeneratedColumn<String> refType = GeneratedColumn<String>(
    'ref_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outboxEventIdMeta = const VerificationMeta(
    'outboxEventId',
  );
  @override
  late final GeneratedColumn<String> outboxEventId = GeneratedColumn<String>(
    'outbox_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    storeId,
    qtyMilli,
    type,
    refType,
    refId,
    outboxEventId,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('ref_type')) {
      context.handle(
        _refTypeMeta,
        refType.isAcceptableOrUnknown(data['ref_type']!, _refTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_refTypeMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    if (data.containsKey('outbox_event_id')) {
      context.handle(
        _outboxEventIdMeta,
        outboxEventId.isAcceptableOrUnknown(
          data['outbox_event_id']!,
          _outboxEventIdMeta,
        ),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      refType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_type'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
      outboxEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outbox_event_id'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class StockMovement extends DataClass implements Insertable<StockMovement> {
  final String id;
  final String productId;
  final String? storeId;

  /// + kirim/qaytarish, − savdo.
  final int qtyMilli;

  /// `receipt` / `sale` / `refund` / `adjustment` / `inventory`.
  final String type;
  final String refType;
  final String refId;
  final String? outboxEventId;
  final DateTime at;
  const StockMovement({
    required this.id,
    required this.productId,
    this.storeId,
    required this.qtyMilli,
    required this.type,
    required this.refType,
    required this.refId,
    this.outboxEventId,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['type'] = Variable<String>(type);
    map['ref_type'] = Variable<String>(refType);
    map['ref_id'] = Variable<String>(refId);
    if (!nullToAbsent || outboxEventId != null) {
      map['outbox_event_id'] = Variable<String>(outboxEventId);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      qtyMilli: Value(qtyMilli),
      type: Value(type),
      refType: Value(refType),
      refId: Value(refId),
      outboxEventId: outboxEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(outboxEventId),
      at: Value(at),
    );
  }

  factory StockMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovement(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      type: serializer.fromJson<String>(json['type']),
      refType: serializer.fromJson<String>(json['refType']),
      refId: serializer.fromJson<String>(json['refId']),
      outboxEventId: serializer.fromJson<String?>(json['outboxEventId']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'storeId': serializer.toJson<String?>(storeId),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'type': serializer.toJson<String>(type),
      'refType': serializer.toJson<String>(refType),
      'refId': serializer.toJson<String>(refId),
      'outboxEventId': serializer.toJson<String?>(outboxEventId),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  StockMovement copyWith({
    String? id,
    String? productId,
    Value<String?> storeId = const Value.absent(),
    int? qtyMilli,
    String? type,
    String? refType,
    String? refId,
    Value<String?> outboxEventId = const Value.absent(),
    DateTime? at,
  }) => StockMovement(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    storeId: storeId.present ? storeId.value : this.storeId,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    type: type ?? this.type,
    refType: refType ?? this.refType,
    refId: refId ?? this.refId,
    outboxEventId: outboxEventId.present
        ? outboxEventId.value
        : this.outboxEventId,
    at: at ?? this.at,
  );
  StockMovement copyWithCompanion(StockMovementsCompanion data) {
    return StockMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      type: data.type.present ? data.type.value : this.type,
      refType: data.refType.present ? data.refType.value : this.refType,
      refId: data.refId.present ? data.refId.value : this.refId,
      outboxEventId: data.outboxEventId.present
          ? data.outboxEventId.value
          : this.outboxEventId,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('type: $type, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('outboxEventId: $outboxEventId, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    storeId,
    qtyMilli,
    type,
    refType,
    refId,
    outboxEventId,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.storeId == this.storeId &&
          other.qtyMilli == this.qtyMilli &&
          other.type == this.type &&
          other.refType == this.refType &&
          other.refId == this.refId &&
          other.outboxEventId == this.outboxEventId &&
          other.at == this.at);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovement> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String?> storeId;
  final Value<int> qtyMilli;
  final Value<String> type;
  final Value<String> refType;
  final Value<String> refId;
  final Value<String?> outboxEventId;
  final Value<DateTime> at;
  final Value<int> rowid;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.type = const Value.absent(),
    this.refType = const Value.absent(),
    this.refId = const Value.absent(),
    this.outboxEventId = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    required String id,
    required String productId,
    this.storeId = const Value.absent(),
    required int qtyMilli,
    required String type,
    required String refType,
    required String refId,
    this.outboxEventId = const Value.absent(),
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       qtyMilli = Value(qtyMilli),
       type = Value(type),
       refType = Value(refType),
       refId = Value(refId),
       at = Value(at);
  static Insertable<StockMovement> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? storeId,
    Expression<int>? qtyMilli,
    Expression<String>? type,
    Expression<String>? refType,
    Expression<String>? refId,
    Expression<String>? outboxEventId,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (storeId != null) 'store_id': storeId,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (type != null) 'type': type,
      if (refType != null) 'ref_type': refType,
      if (refId != null) 'ref_id': refId,
      if (outboxEventId != null) 'outbox_event_id': outboxEventId,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String?>? storeId,
    Value<int>? qtyMilli,
    Value<String>? type,
    Value<String>? refType,
    Value<String>? refId,
    Value<String?>? outboxEventId,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      type: type ?? this.type,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      outboxEventId: outboxEventId ?? this.outboxEventId,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (refType.present) {
      map['ref_type'] = Variable<String>(refType.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (outboxEventId.present) {
      map['outbox_event_id'] = Variable<String>(outboxEventId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('type: $type, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('outboxEventId: $outboxEventId, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEventsTable extends OutboxEvents
    with TableInfo<$OutboxEventsTable, OutboxEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    payload,
    createdAt,
    status,
    attempts,
    lastError,
    nextAttemptAt,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
    );
  }

  @override
  $OutboxEventsTable createAlias(String alias) {
    return $OutboxEventsTable(attachedDatabase, alias);
  }
}

class OutboxEvent extends DataClass implements Insertable<OutboxEvent> {
  /// Hodisa UUIDv7 (server shu bo'yicha idempotent).
  final String id;

  /// `sale.completed`, `shift.opened`, ...
  final String type;

  /// JSON.
  final String payload;
  final DateTime createdAt;

  /// `pending` — yuborilmagan; `sent` — applied/duplicate/pending;
  /// `rejected` — server rad etdi, qayta yuborilmaydi.
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;
  final DateTime? sentAt;
  const OutboxEvent({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.status,
    required this.attempts,
    this.lastError,
    this.nextAttemptAt,
    this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    return map;
  }

  OutboxEventsCompanion toCompanion(bool nullToAbsent) {
    return OutboxEventsCompanion(
      id: Value(id),
      type: Value(type),
      payload: Value(payload),
      createdAt: Value(createdAt),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
    );
  }

  factory OutboxEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEvent(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
    };
  }

  OutboxEvent copyWith({
    String? id,
    String? type,
    String? payload,
    DateTime? createdAt,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<DateTime?> sentAt = const Value.absent(),
  }) => OutboxEvent(
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
  );
  OutboxEvent copyWithCompanion(OutboxEventsCompanion data) {
    return OutboxEvent(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEvent(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    payload,
    createdAt,
    status,
    attempts,
    lastError,
    nextAttemptAt,
    sentAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEvent &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.sentAt == this.sentAt);
}

class OutboxEventsCompanion extends UpdateCompanion<OutboxEvent> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime?> sentAt;
  final Value<int> rowid;
  const OutboxEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEventsCompanion.insert({
    required String id,
    required String type,
    required String payload,
    required DateTime createdAt,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxEvent> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
    Value<DateTime?>? sentAt,
    Value<int>? rowid,
  }) {
    return OutboxEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _pullCursorMeta = const VerificationMeta(
    'pullCursor',
  );
  @override
  late final GeneratedColumn<String> pullCursor = GeneratedColumn<String>(
    'pull_cursor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _lastPushAtMeta = const VerificationMeta(
    'lastPushAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPushAt = GeneratedColumn<DateTime>(
    'last_push_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subscriptionJsonMeta = const VerificationMeta(
    'subscriptionJson',
  );
  @override
  late final GeneratedColumn<String> subscriptionJson = GeneratedColumn<String>(
    'subscription_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offlineGraceUntilMeta = const VerificationMeta(
    'offlineGraceUntil',
  );
  @override
  late final GeneratedColumn<DateTime> offlineGraceUntil =
      GeneratedColumn<DateTime>(
        'offline_grace_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverTimeOffsetMsMeta =
      const VerificationMeta('serverTimeOffsetMs');
  @override
  late final GeneratedColumn<int> serverTimeOffsetMs = GeneratedColumn<int>(
    'server_time_offset_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pullCursor,
    lastPushAt,
    lastPullAt,
    subscriptionJson,
    offlineGraceUntil,
    serverTimeOffsetMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pull_cursor')) {
      context.handle(
        _pullCursorMeta,
        pullCursor.isAcceptableOrUnknown(data['pull_cursor']!, _pullCursorMeta),
      );
    }
    if (data.containsKey('last_push_at')) {
      context.handle(
        _lastPushAtMeta,
        lastPushAt.isAcceptableOrUnknown(
          data['last_push_at']!,
          _lastPushAtMeta,
        ),
      );
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    }
    if (data.containsKey('subscription_json')) {
      context.handle(
        _subscriptionJsonMeta,
        subscriptionJson.isAcceptableOrUnknown(
          data['subscription_json']!,
          _subscriptionJsonMeta,
        ),
      );
    }
    if (data.containsKey('offline_grace_until')) {
      context.handle(
        _offlineGraceUntilMeta,
        offlineGraceUntil.isAcceptableOrUnknown(
          data['offline_grace_until']!,
          _offlineGraceUntilMeta,
        ),
      );
    }
    if (data.containsKey('server_time_offset_ms')) {
      context.handle(
        _serverTimeOffsetMsMeta,
        serverTimeOffsetMs.isAcceptableOrUnknown(
          data['server_time_offset_ms']!,
          _serverTimeOffsetMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pullCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pull_cursor'],
      )!,
      lastPushAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_push_at'],
      ),
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      ),
      subscriptionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_json'],
      ),
      offlineGraceUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}offline_grace_until'],
      ),
      serverTimeOffsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_time_offset_ms'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final int id;

  /// Pull kursori (ochiq bo'lmagan satr, boshida `"0"`).
  final String pullCursor;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;

  /// Oxirgi pull'dagi `subscription` (JSON).
  final String? subscriptionJson;

  /// Shu vaqtdan keyin oflayn savdo to'xtaydi (`server_time + offline_days`).
  final DateTime? offlineGraceUntil;

  /// `server_time − qurilma vaqti` (ms).
  final int serverTimeOffsetMs;
  const SyncStateData({
    required this.id,
    required this.pullCursor,
    this.lastPushAt,
    this.lastPullAt,
    this.subscriptionJson,
    this.offlineGraceUntil,
    required this.serverTimeOffsetMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pull_cursor'] = Variable<String>(pullCursor);
    if (!nullToAbsent || lastPushAt != null) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt);
    }
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    }
    if (!nullToAbsent || subscriptionJson != null) {
      map['subscription_json'] = Variable<String>(subscriptionJson);
    }
    if (!nullToAbsent || offlineGraceUntil != null) {
      map['offline_grace_until'] = Variable<DateTime>(offlineGraceUntil);
    }
    map['server_time_offset_ms'] = Variable<int>(serverTimeOffsetMs);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      pullCursor: Value(pullCursor),
      lastPushAt: lastPushAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushAt),
      lastPullAt: lastPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullAt),
      subscriptionJson: subscriptionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(subscriptionJson),
      offlineGraceUntil: offlineGraceUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(offlineGraceUntil),
      serverTimeOffsetMs: Value(serverTimeOffsetMs),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      id: serializer.fromJson<int>(json['id']),
      pullCursor: serializer.fromJson<String>(json['pullCursor']),
      lastPushAt: serializer.fromJson<DateTime?>(json['lastPushAt']),
      lastPullAt: serializer.fromJson<DateTime?>(json['lastPullAt']),
      subscriptionJson: serializer.fromJson<String?>(json['subscriptionJson']),
      offlineGraceUntil: serializer.fromJson<DateTime?>(
        json['offlineGraceUntil'],
      ),
      serverTimeOffsetMs: serializer.fromJson<int>(json['serverTimeOffsetMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pullCursor': serializer.toJson<String>(pullCursor),
      'lastPushAt': serializer.toJson<DateTime?>(lastPushAt),
      'lastPullAt': serializer.toJson<DateTime?>(lastPullAt),
      'subscriptionJson': serializer.toJson<String?>(subscriptionJson),
      'offlineGraceUntil': serializer.toJson<DateTime?>(offlineGraceUntil),
      'serverTimeOffsetMs': serializer.toJson<int>(serverTimeOffsetMs),
    };
  }

  SyncStateData copyWith({
    int? id,
    String? pullCursor,
    Value<DateTime?> lastPushAt = const Value.absent(),
    Value<DateTime?> lastPullAt = const Value.absent(),
    Value<String?> subscriptionJson = const Value.absent(),
    Value<DateTime?> offlineGraceUntil = const Value.absent(),
    int? serverTimeOffsetMs,
  }) => SyncStateData(
    id: id ?? this.id,
    pullCursor: pullCursor ?? this.pullCursor,
    lastPushAt: lastPushAt.present ? lastPushAt.value : this.lastPushAt,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
    subscriptionJson: subscriptionJson.present
        ? subscriptionJson.value
        : this.subscriptionJson,
    offlineGraceUntil: offlineGraceUntil.present
        ? offlineGraceUntil.value
        : this.offlineGraceUntil,
    serverTimeOffsetMs: serverTimeOffsetMs ?? this.serverTimeOffsetMs,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      id: data.id.present ? data.id.value : this.id,
      pullCursor: data.pullCursor.present
          ? data.pullCursor.value
          : this.pullCursor,
      lastPushAt: data.lastPushAt.present
          ? data.lastPushAt.value
          : this.lastPushAt,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
      subscriptionJson: data.subscriptionJson.present
          ? data.subscriptionJson.value
          : this.subscriptionJson,
      offlineGraceUntil: data.offlineGraceUntil.present
          ? data.offlineGraceUntil.value
          : this.offlineGraceUntil,
      serverTimeOffsetMs: data.serverTimeOffsetMs.present
          ? data.serverTimeOffsetMs.value
          : this.serverTimeOffsetMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('id: $id, ')
          ..write('pullCursor: $pullCursor, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('subscriptionJson: $subscriptionJson, ')
          ..write('offlineGraceUntil: $offlineGraceUntil, ')
          ..write('serverTimeOffsetMs: $serverTimeOffsetMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pullCursor,
    lastPushAt,
    lastPullAt,
    subscriptionJson,
    offlineGraceUntil,
    serverTimeOffsetMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.id == this.id &&
          other.pullCursor == this.pullCursor &&
          other.lastPushAt == this.lastPushAt &&
          other.lastPullAt == this.lastPullAt &&
          other.subscriptionJson == this.subscriptionJson &&
          other.offlineGraceUntil == this.offlineGraceUntil &&
          other.serverTimeOffsetMs == this.serverTimeOffsetMs);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<int> id;
  final Value<String> pullCursor;
  final Value<DateTime?> lastPushAt;
  final Value<DateTime?> lastPullAt;
  final Value<String?> subscriptionJson;
  final Value<DateTime?> offlineGraceUntil;
  final Value<int> serverTimeOffsetMs;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.pullCursor = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.subscriptionJson = const Value.absent(),
    this.offlineGraceUntil = const Value.absent(),
    this.serverTimeOffsetMs = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    this.pullCursor = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.subscriptionJson = const Value.absent(),
    this.offlineGraceUntil = const Value.absent(),
    this.serverTimeOffsetMs = const Value.absent(),
  });
  static Insertable<SyncStateData> custom({
    Expression<int>? id,
    Expression<String>? pullCursor,
    Expression<DateTime>? lastPushAt,
    Expression<DateTime>? lastPullAt,
    Expression<String>? subscriptionJson,
    Expression<DateTime>? offlineGraceUntil,
    Expression<int>? serverTimeOffsetMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pullCursor != null) 'pull_cursor': pullCursor,
      if (lastPushAt != null) 'last_push_at': lastPushAt,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (subscriptionJson != null) 'subscription_json': subscriptionJson,
      if (offlineGraceUntil != null) 'offline_grace_until': offlineGraceUntil,
      if (serverTimeOffsetMs != null)
        'server_time_offset_ms': serverTimeOffsetMs,
    });
  }

  SyncStateCompanion copyWith({
    Value<int>? id,
    Value<String>? pullCursor,
    Value<DateTime?>? lastPushAt,
    Value<DateTime?>? lastPullAt,
    Value<String?>? subscriptionJson,
    Value<DateTime?>? offlineGraceUntil,
    Value<int>? serverTimeOffsetMs,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      pullCursor: pullCursor ?? this.pullCursor,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      subscriptionJson: subscriptionJson ?? this.subscriptionJson,
      offlineGraceUntil: offlineGraceUntil ?? this.offlineGraceUntil,
      serverTimeOffsetMs: serverTimeOffsetMs ?? this.serverTimeOffsetMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pullCursor.present) {
      map['pull_cursor'] = Variable<String>(pullCursor.value);
    }
    if (lastPushAt.present) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (subscriptionJson.present) {
      map['subscription_json'] = Variable<String>(subscriptionJson.value);
    }
    if (offlineGraceUntil.present) {
      map['offline_grace_until'] = Variable<DateTime>(offlineGraceUntil.value);
    }
    if (serverTimeOffsetMs.present) {
      map['server_time_offset_ms'] = Variable<int>(serverTimeOffsetMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('pullCursor: $pullCursor, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('subscriptionJson: $subscriptionJson, ')
          ..write('offlineGraceUntil: $offlineGraceUntil, ')
          ..write('serverTimeOffsetMs: $serverTimeOffsetMs')
          ..write(')'))
        .toString();
  }
}

class $CartDraftsTable extends CartDrafts
    with TableInfo<$CartDraftsTable, CartDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CartDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linesJsonMeta = const VerificationMeta(
    'linesJson',
  );
  @override
  late final GeneratedColumn<String> linesJson = GeneratedColumn<String>(
    'lines_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _discountJsonMeta = const VerificationMeta(
    'discountJson',
  );
  @override
  late final GeneratedColumn<String> discountJson = GeneratedColumn<String>(
    'discount_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slot,
    customerId,
    linesJson,
    discountJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cart_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CartDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('lines_json')) {
      context.handle(
        _linesJsonMeta,
        linesJson.isAcceptableOrUnknown(data['lines_json']!, _linesJsonMeta),
      );
    }
    if (data.containsKey('discount_json')) {
      context.handle(
        _discountJsonMeta,
        discountJson.isAcceptableOrUnknown(
          data['discount_json']!,
          _discountJsonMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CartDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CartDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      linesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lines_json'],
      )!,
      discountJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CartDraftsTable createAlias(String alias) {
    return $CartDraftsTable(attachedDatabase, alias);
  }
}

class CartDraft extends DataClass implements Insertable<CartDraft> {
  final String id;

  /// Tab tartibi (0..4).
  final int slot;
  final String? customerId;

  /// Savat qatorlari (JSON).
  final String linesJson;

  /// Chek chegirmasi (JSON: `percent_bp` yoki `amount_tiyin`), v3.
  final String? discountJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CartDraft({
    required this.id,
    required this.slot,
    this.customerId,
    required this.linesJson,
    this.discountJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slot'] = Variable<int>(slot);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['lines_json'] = Variable<String>(linesJson);
    if (!nullToAbsent || discountJson != null) {
      map['discount_json'] = Variable<String>(discountJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CartDraftsCompanion toCompanion(bool nullToAbsent) {
    return CartDraftsCompanion(
      id: Value(id),
      slot: Value(slot),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      linesJson: Value(linesJson),
      discountJson: discountJson == null && nullToAbsent
          ? const Value.absent()
          : Value(discountJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CartDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CartDraft(
      id: serializer.fromJson<String>(json['id']),
      slot: serializer.fromJson<int>(json['slot']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      linesJson: serializer.fromJson<String>(json['linesJson']),
      discountJson: serializer.fromJson<String?>(json['discountJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slot': serializer.toJson<int>(slot),
      'customerId': serializer.toJson<String?>(customerId),
      'linesJson': serializer.toJson<String>(linesJson),
      'discountJson': serializer.toJson<String?>(discountJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CartDraft copyWith({
    String? id,
    int? slot,
    Value<String?> customerId = const Value.absent(),
    String? linesJson,
    Value<String?> discountJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CartDraft(
    id: id ?? this.id,
    slot: slot ?? this.slot,
    customerId: customerId.present ? customerId.value : this.customerId,
    linesJson: linesJson ?? this.linesJson,
    discountJson: discountJson.present ? discountJson.value : this.discountJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CartDraft copyWithCompanion(CartDraftsCompanion data) {
    return CartDraft(
      id: data.id.present ? data.id.value : this.id,
      slot: data.slot.present ? data.slot.value : this.slot,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      linesJson: data.linesJson.present ? data.linesJson.value : this.linesJson,
      discountJson: data.discountJson.present
          ? data.discountJson.value
          : this.discountJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CartDraft(')
          ..write('id: $id, ')
          ..write('slot: $slot, ')
          ..write('customerId: $customerId, ')
          ..write('linesJson: $linesJson, ')
          ..write('discountJson: $discountJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    slot,
    customerId,
    linesJson,
    discountJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartDraft &&
          other.id == this.id &&
          other.slot == this.slot &&
          other.customerId == this.customerId &&
          other.linesJson == this.linesJson &&
          other.discountJson == this.discountJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CartDraftsCompanion extends UpdateCompanion<CartDraft> {
  final Value<String> id;
  final Value<int> slot;
  final Value<String?> customerId;
  final Value<String> linesJson;
  final Value<String?> discountJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CartDraftsCompanion({
    this.id = const Value.absent(),
    this.slot = const Value.absent(),
    this.customerId = const Value.absent(),
    this.linesJson = const Value.absent(),
    this.discountJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CartDraftsCompanion.insert({
    required String id,
    required int slot,
    this.customerId = const Value.absent(),
    this.linesJson = const Value.absent(),
    this.discountJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slot = Value(slot),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CartDraft> custom({
    Expression<String>? id,
    Expression<int>? slot,
    Expression<String>? customerId,
    Expression<String>? linesJson,
    Expression<String>? discountJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slot != null) 'slot': slot,
      if (customerId != null) 'customer_id': customerId,
      if (linesJson != null) 'lines_json': linesJson,
      if (discountJson != null) 'discount_json': discountJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CartDraftsCompanion copyWith({
    Value<String>? id,
    Value<int>? slot,
    Value<String?>? customerId,
    Value<String>? linesJson,
    Value<String?>? discountJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CartDraftsCompanion(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      customerId: customerId ?? this.customerId,
      linesJson: linesJson ?? this.linesJson,
      discountJson: discountJson ?? this.discountJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (linesJson.present) {
      map['lines_json'] = Variable<String>(linesJson.value);
    }
    if (discountJson.present) {
      map['discount_json'] = Variable<String>(discountJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartDraftsCompanion(')
          ..write('id: $id, ')
          ..write('slot: $slot, ')
          ..write('customerId: $customerId, ')
          ..write('linesJson: $linesJson, ')
          ..write('discountJson: $discountJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocCountersTable extends DocCounters
    with TableInfo<$DocCountersTable, DocCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'doc_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocCounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  DocCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocCounter(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $DocCountersTable createAlias(String alias) {
    return $DocCountersTable(attachedDatabase, alias);
  }
}

class DocCounter extends DataClass implements Insertable<DocCounter> {
  final String name;
  final int value;
  const DocCounter({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<int>(value);
    return map;
  }

  DocCountersCompanion toCompanion(bool nullToAbsent) {
    return DocCountersCompanion(name: Value(name), value: Value(value));
  }

  factory DocCounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocCounter(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<int>(value),
    };
  }

  DocCounter copyWith({String? name, int? value}) =>
      DocCounter(name: name ?? this.name, value: value ?? this.value);
  DocCounter copyWithCompanion(DocCountersCompanion data) {
    return DocCounter(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocCounter(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocCounter &&
          other.name == this.name &&
          other.value == this.value);
}

class DocCountersCompanion extends UpdateCompanion<DocCounter> {
  final Value<String> name;
  final Value<int> value;
  final Value<int> rowid;
  const DocCountersCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocCountersCompanion.insert({
    required String name,
    required int value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<DocCounter> custom({
    Expression<String>? name,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocCountersCompanion copyWith({
    Value<String>? name,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return DocCountersCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocCountersCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductImagesTable extends ProductImages
    with TableInfo<$ProductImagesTable, ProductImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byUserIdMeta = const VerificationMeta(
    'byUserId',
  );
  @override
  late final GeneratedColumn<String> byUserId = GeneratedColumn<String>(
    'by_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    state,
    byUserId,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('by_user_id')) {
      context.handle(
        _byUserIdMeta,
        byUserId.isAcceptableOrUnknown(data['by_user_id']!, _byUserIdMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      byUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}by_user_id'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProductImagesTable createAlias(String alias) {
    return $ProductImagesTable(attachedDatabase, alias);
  }
}

class ProductImage extends DataClass implements Insertable<ProductImage> {
  final String id;
  final String productId;
  final String state;

  /// Yuklagan ega/menejer (server huquqni tekshiradi).
  final String? byUserId;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  const ProductImage({
    required this.id,
    required this.productId,
    required this.state,
    this.byUserId,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || byUserId != null) {
      map['by_user_id'] = Variable<String>(byUserId);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductImagesCompanion toCompanion(bool nullToAbsent) {
    return ProductImagesCompanion(
      id: Value(id),
      productId: Value(productId),
      state: Value(state),
      byUserId: byUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(byUserId),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory ProductImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductImage(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      state: serializer.fromJson<String>(json['state']),
      byUserId: serializer.fromJson<String?>(json['byUserId']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'state': serializer.toJson<String>(state),
      'byUserId': serializer.toJson<String?>(byUserId),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProductImage copyWith({
    String? id,
    String? productId,
    String? state,
    Value<String?> byUserId = const Value.absent(),
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => ProductImage(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    state: state ?? this.state,
    byUserId: byUserId.present ? byUserId.value : this.byUserId,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  ProductImage copyWithCompanion(ProductImagesCompanion data) {
    return ProductImage(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      state: data.state.present ? data.state.value : this.state,
      byUserId: data.byUserId.present ? data.byUserId.value : this.byUserId,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductImage(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('state: $state, ')
          ..write('byUserId: $byUserId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    state,
    byUserId,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductImage &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.state == this.state &&
          other.byUserId == this.byUserId &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class ProductImagesCompanion extends UpdateCompanion<ProductImage> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> state;
  final Value<String?> byUserId;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProductImagesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.state = const Value.absent(),
    this.byUserId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductImagesCompanion.insert({
    required String id,
    required String productId,
    required String state,
    this.byUserId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<ProductImage> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? state,
    Expression<String>? byUserId,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (state != null) 'state': state,
      if (byUserId != null) 'by_user_id': byUserId,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductImagesCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? state,
    Value<String?>? byUserId,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProductImagesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      state: state ?? this.state,
      byUserId: byUserId ?? this.byUserId,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (byUserId.present) {
      map['by_user_id'] = Variable<String>(byUserId.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductImagesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('state: $state, ')
          ..write('byUserId: $byUserId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $StoresTable stores = $StoresTable(this);
  late final $StaffUsersTable staffUsers = $StaffUsersTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductBarcodesTable productBarcodes = $ProductBarcodesTable(
    this,
  );
  late final $CustomersTable customers = $CustomersTable(this);
  late final $SuppliersTable suppliers = $SuppliersTable(this);
  late final $ProductStockTable productStock = $ProductStockTable(this);
  late final $DebtEntriesTable debtEntries = $DebtEntriesTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $SaleItemsTable saleItems = $SaleItemsTable(this);
  late final $SalePaymentsTable salePayments = $SalePaymentsTable(this);
  late final $RefundsTable refunds = $RefundsTable(this);
  late final $RefundItemsTable refundItems = $RefundItemsTable(this);
  late final $CashMovementsTable cashMovements = $CashMovementsTable(this);
  late final $StockReceiptsTable stockReceipts = $StockReceiptsTable(this);
  late final $StockReceiptItemsTable stockReceiptItems =
      $StockReceiptItemsTable(this);
  late final $InventoryCountsTable inventoryCounts = $InventoryCountsTable(
    this,
  );
  late final $InventoryCountItemsTable inventoryCountItems =
      $InventoryCountItemsTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $OutboxEventsTable outboxEvents = $OutboxEventsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $CartDraftsTable cartDrafts = $CartDraftsTable(this);
  late final $DocCountersTable docCounters = $DocCountersTable(this);
  late final $ProductImagesTable productImages = $ProductImagesTable(this);
  late final Index productsPlu = Index(
    'products_plu',
    'CREATE INDEX products_plu ON products (plu_code)',
  );
  late final Index productsSearch = Index(
    'products_search',
    'CREATE INDEX products_search ON products (search_key)',
  );
  late final Index productsQuick = Index(
    'products_quick',
    'CREATE INDEX products_quick ON products (quick_button)',
  );
  late final Index productBarcodesProduct = Index(
    'product_barcodes_product',
    'CREATE INDEX product_barcodes_product ON product_barcodes (product_id)',
  );
  late final Index debtEntriesCustomer = Index(
    'debt_entries_customer',
    'CREATE INDEX debt_entries_customer ON debt_entries (customer_id)',
  );
  late final Index shiftsOneOpenPerDevice = Index(
    'shifts_one_open_per_device',
    'CREATE UNIQUE INDEX shifts_one_open_per_device ON shifts (device_id) WHERE closed_at IS NULL',
  );
  late final Index salesShift = Index(
    'sales_shift',
    'CREATE INDEX sales_shift ON sales (shift_id)',
  );
  late final Index salesSoldAt = Index(
    'sales_sold_at',
    'CREATE INDEX sales_sold_at ON sales (sold_at)',
  );
  late final Index saleItemsSale = Index(
    'sale_items_sale',
    'CREATE INDEX sale_items_sale ON sale_items (sale_id)',
  );
  late final Index salePaymentsSale = Index(
    'sale_payments_sale',
    'CREATE INDEX sale_payments_sale ON sale_payments (sale_id)',
  );
  late final Index refundsSale = Index(
    'refunds_sale',
    'CREATE INDEX refunds_sale ON refunds (sale_id)',
  );
  late final Index inventoryCountItemsUniqueProduct = Index(
    'inventory_count_items_unique_product',
    'CREATE UNIQUE INDEX inventory_count_items_unique_product ON inventory_count_items (count_id, product_id)',
  );
  late final Index stockMovementsProduct = Index(
    'stock_movements_product',
    'CREATE INDEX stock_movements_product ON stock_movements (product_id)',
  );
  late final Index stockMovementsEvent = Index(
    'stock_movements_event',
    'CREATE INDEX stock_movements_event ON stock_movements (outbox_event_id)',
  );
  late final Index outboxEventsQueue = Index(
    'outbox_events_queue',
    'CREATE INDEX outbox_events_queue ON outbox_events (status, created_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localSettings,
    stores,
    staffUsers,
    units,
    categories,
    products,
    productBarcodes,
    customers,
    suppliers,
    productStock,
    debtEntries,
    shifts,
    sales,
    saleItems,
    salePayments,
    refunds,
    refundItems,
    cashMovements,
    stockReceipts,
    stockReceiptItems,
    inventoryCounts,
    inventoryCountItems,
    stockMovements,
    outboxEvents,
    syncState,
    cartDrafts,
    docCounters,
    productImages,
    productsPlu,
    productsSearch,
    productsQuick,
    productBarcodesProduct,
    debtEntriesCustomer,
    shiftsOneOpenPerDevice,
    salesShift,
    salesSoldAt,
    saleItemsSale,
    salePaymentsSale,
    refundsSale,
    inventoryCountItemsUniqueProduct,
    stockMovementsProduct,
    stockMovementsEvent,
    outboxEventsQueue,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;
typedef $$StoresTableCreateCompanionBuilder =
    StoresCompanion Function({
      required String id,
      required String name,
      Value<String> address,
      Value<String> phone,
      Value<String> receiptHeader,
      Value<String> receiptFooter,
      Value<String> legalName,
      Value<String> tin,
      Value<String> receiptLogo,
      Value<String> receiptOptions,
      Value<int> rowid,
    });
typedef $$StoresTableUpdateCompanionBuilder =
    StoresCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> address,
      Value<String> phone,
      Value<String> receiptHeader,
      Value<String> receiptFooter,
      Value<String> legalName,
      Value<String> tin,
      Value<String> receiptLogo,
      Value<String> receiptOptions,
      Value<int> rowid,
    });

class $$StoresTableFilterComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tin => $composableBuilder(
    column: $table.tin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptLogo => $composableBuilder(
    column: $table.receiptLogo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptOptions => $composableBuilder(
    column: $table.receiptOptions,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoresTableOrderingComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tin => $composableBuilder(
    column: $table.tin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptLogo => $composableBuilder(
    column: $table.receiptLogo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptOptions => $composableBuilder(
    column: $table.receiptOptions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legalName =>
      $composableBuilder(column: $table.legalName, builder: (column) => column);

  GeneratedColumn<String> get tin =>
      $composableBuilder(column: $table.tin, builder: (column) => column);

  GeneratedColumn<String> get receiptLogo => $composableBuilder(
    column: $table.receiptLogo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptOptions => $composableBuilder(
    column: $table.receiptOptions,
    builder: (column) => column,
  );
}

class $$StoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoresTable,
          Store,
          $$StoresTableFilterComposer,
          $$StoresTableOrderingComposer,
          $$StoresTableAnnotationComposer,
          $$StoresTableCreateCompanionBuilder,
          $$StoresTableUpdateCompanionBuilder,
          (Store, BaseReferences<_$AppDatabase, $StoresTable, Store>),
          Store,
          PrefetchHooks Function()
        > {
  $$StoresTableTableManager(_$AppDatabase db, $StoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> receiptHeader = const Value.absent(),
                Value<String> receiptFooter = const Value.absent(),
                Value<String> legalName = const Value.absent(),
                Value<String> tin = const Value.absent(),
                Value<String> receiptLogo = const Value.absent(),
                Value<String> receiptOptions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresCompanion(
                id: id,
                name: name,
                address: address,
                phone: phone,
                receiptHeader: receiptHeader,
                receiptFooter: receiptFooter,
                legalName: legalName,
                tin: tin,
                receiptLogo: receiptLogo,
                receiptOptions: receiptOptions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> address = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> receiptHeader = const Value.absent(),
                Value<String> receiptFooter = const Value.absent(),
                Value<String> legalName = const Value.absent(),
                Value<String> tin = const Value.absent(),
                Value<String> receiptLogo = const Value.absent(),
                Value<String> receiptOptions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresCompanion.insert(
                id: id,
                name: name,
                address: address,
                phone: phone,
                receiptHeader: receiptHeader,
                receiptFooter: receiptFooter,
                legalName: legalName,
                tin: tin,
                receiptLogo: receiptLogo,
                receiptOptions: receiptOptions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoresTable,
      Store,
      $$StoresTableFilterComposer,
      $$StoresTableOrderingComposer,
      $$StoresTableAnnotationComposer,
      $$StoresTableCreateCompanionBuilder,
      $$StoresTableUpdateCompanionBuilder,
      (Store, BaseReferences<_$AppDatabase, $StoresTable, Store>),
      Store,
      PrefetchHooks Function()
    >;
typedef $$StaffUsersTableCreateCompanionBuilder =
    StaffUsersCompanion Function({
      required String id,
      Value<String?> phone,
      required String fullName,
      required String role,
      Value<bool> isActive,
      Value<String?> pinHash,
      Value<int> rowid,
    });
typedef $$StaffUsersTableUpdateCompanionBuilder =
    StaffUsersCompanion Function({
      Value<String> id,
      Value<String?> phone,
      Value<String> fullName,
      Value<String> role,
      Value<bool> isActive,
      Value<String?> pinHash,
      Value<int> rowid,
    });

class $$StaffUsersTableFilterComposer
    extends Composer<_$AppDatabase, $StaffUsersTable> {
  $$StaffUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffUsersTable> {
  $$StaffUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffUsersTable> {
  $$StaffUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);
}

class $$StaffUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffUsersTable,
          StaffUser,
          $$StaffUsersTableFilterComposer,
          $$StaffUsersTableOrderingComposer,
          $$StaffUsersTableAnnotationComposer,
          $$StaffUsersTableCreateCompanionBuilder,
          $$StaffUsersTableUpdateCompanionBuilder,
          (
            StaffUser,
            BaseReferences<_$AppDatabase, $StaffUsersTable, StaffUser>,
          ),
          StaffUser,
          PrefetchHooks Function()
        > {
  $$StaffUsersTableTableManager(_$AppDatabase db, $StaffUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StaffUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StaffUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffUsersCompanion(
                id: id,
                phone: phone,
                fullName: fullName,
                role: role,
                isActive: isActive,
                pinHash: pinHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> phone = const Value.absent(),
                required String fullName,
                required String role,
                Value<bool> isActive = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffUsersCompanion.insert(
                id: id,
                phone: phone,
                fullName: fullName,
                role: role,
                isActive: isActive,
                pinHash: pinHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffUsersTable,
      StaffUser,
      $$StaffUsersTableFilterComposer,
      $$StaffUsersTableOrderingComposer,
      $$StaffUsersTableAnnotationComposer,
      $$StaffUsersTableCreateCompanionBuilder,
      $$StaffUsersTableUpdateCompanionBuilder,
      (StaffUser, BaseReferences<_$AppDatabase, $StaffUsersTable, StaffUser>),
      StaffUser,
      PrefetchHooks Function()
    >;
typedef $$UnitsTableCreateCompanionBuilder =
    UnitsCompanion Function({
      required String id,
      required String code,
      Value<String> name,
      Value<bool> isFractional,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$UnitsTableUpdateCompanionBuilder =
    UnitsCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<bool> isFractional,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$UnitsTableFilterComposer extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFractional => $composableBuilder(
    column: $table.isFractional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFractional => $composableBuilder(
    column: $table.isFractional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isFractional => $composableBuilder(
    column: $table.isFractional,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$UnitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnitsTable,
          Unit,
          $$UnitsTableFilterComposer,
          $$UnitsTableOrderingComposer,
          $$UnitsTableAnnotationComposer,
          $$UnitsTableCreateCompanionBuilder,
          $$UnitsTableUpdateCompanionBuilder,
          (Unit, BaseReferences<_$AppDatabase, $UnitsTable, Unit>),
          Unit,
          PrefetchHooks Function()
        > {
  $$UnitsTableTableManager(_$AppDatabase db, $UnitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isFractional = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitsCompanion(
                id: id,
                code: code,
                name: name,
                isFractional: isFractional,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                Value<String> name = const Value.absent(),
                Value<bool> isFractional = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitsCompanion.insert(
                id: id,
                code: code,
                name: name,
                isFractional: isFractional,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnitsTable,
      Unit,
      $$UnitsTableFilterComposer,
      $$UnitsTableOrderingComposer,
      $$UnitsTableAnnotationComposer,
      $$UnitsTableCreateCompanionBuilder,
      $$UnitsTableUpdateCompanionBuilder,
      (Unit, BaseReferences<_$AppDatabase, $UnitsTable, Unit>),
      Unit,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      Value<String?> parentId,
      Value<int> sort,
      Value<String?> color,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<int> sort,
      Value<String?> color,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                parentId: parentId,
                sort: sort,
                color: color,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                sort: sort,
                color: color,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String name,
      Value<String> searchKey,
      Value<String?> categoryId,
      required String unitId,
      required int sellPriceTiyin,
      Value<int> costPriceTiyin,
      Value<bool> isWeighted,
      Value<String?> pluCode,
      Value<int> minStockMilli,
      Value<String?> ikpuCode,
      Value<bool> quickButton,
      Value<bool> isActive,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> imageId,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> searchKey,
      Value<String?> categoryId,
      Value<String> unitId,
      Value<int> sellPriceTiyin,
      Value<int> costPriceTiyin,
      Value<bool> isWeighted,
      Value<String?> pluCode,
      Value<int> minStockMilli,
      Value<String?> ikpuCode,
      Value<bool> quickButton,
      Value<bool> isActive,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> imageId,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchKey => $composableBuilder(
    column: $table.searchKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellPriceTiyin => $composableBuilder(
    column: $table.sellPriceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPriceTiyin => $composableBuilder(
    column: $table.costPriceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluCode => $composableBuilder(
    column: $table.pluCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minStockMilli => $composableBuilder(
    column: $table.minStockMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ikpuCode => $composableBuilder(
    column: $table.ikpuCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quickButton => $composableBuilder(
    column: $table.quickButton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageId => $composableBuilder(
    column: $table.imageId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchKey => $composableBuilder(
    column: $table.searchKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellPriceTiyin => $composableBuilder(
    column: $table.sellPriceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPriceTiyin => $composableBuilder(
    column: $table.costPriceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluCode => $composableBuilder(
    column: $table.pluCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minStockMilli => $composableBuilder(
    column: $table.minStockMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ikpuCode => $composableBuilder(
    column: $table.ikpuCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quickButton => $composableBuilder(
    column: $table.quickButton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageId => $composableBuilder(
    column: $table.imageId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get searchKey =>
      $composableBuilder(column: $table.searchKey, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<int> get sellPriceTiyin => $composableBuilder(
    column: $table.sellPriceTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costPriceTiyin => $composableBuilder(
    column: $table.costPriceTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluCode =>
      $composableBuilder(column: $table.pluCode, builder: (column) => column);

  GeneratedColumn<int> get minStockMilli => $composableBuilder(
    column: $table.minStockMilli,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ikpuCode =>
      $composableBuilder(column: $table.ikpuCode, builder: (column) => column);

  GeneratedColumn<bool> get quickButton => $composableBuilder(
    column: $table.quickButton,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get imageId =>
      $composableBuilder(column: $table.imageId, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> searchKey = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> unitId = const Value.absent(),
                Value<int> sellPriceTiyin = const Value.absent(),
                Value<int> costPriceTiyin = const Value.absent(),
                Value<bool> isWeighted = const Value.absent(),
                Value<String?> pluCode = const Value.absent(),
                Value<int> minStockMilli = const Value.absent(),
                Value<String?> ikpuCode = const Value.absent(),
                Value<bool> quickButton = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> imageId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                searchKey: searchKey,
                categoryId: categoryId,
                unitId: unitId,
                sellPriceTiyin: sellPriceTiyin,
                costPriceTiyin: costPriceTiyin,
                isWeighted: isWeighted,
                pluCode: pluCode,
                minStockMilli: minStockMilli,
                ikpuCode: ikpuCode,
                quickButton: quickButton,
                isActive: isActive,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                imageId: imageId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> searchKey = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required String unitId,
                required int sellPriceTiyin,
                Value<int> costPriceTiyin = const Value.absent(),
                Value<bool> isWeighted = const Value.absent(),
                Value<String?> pluCode = const Value.absent(),
                Value<int> minStockMilli = const Value.absent(),
                Value<String?> ikpuCode = const Value.absent(),
                Value<bool> quickButton = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> imageId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                searchKey: searchKey,
                categoryId: categoryId,
                unitId: unitId,
                sellPriceTiyin: sellPriceTiyin,
                costPriceTiyin: costPriceTiyin,
                isWeighted: isWeighted,
                pluCode: pluCode,
                minStockMilli: minStockMilli,
                ikpuCode: ikpuCode,
                quickButton: quickButton,
                isActive: isActive,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                imageId: imageId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$ProductBarcodesTableCreateCompanionBuilder =
    ProductBarcodesCompanion Function({
      required String barcode,
      required String productId,
      Value<bool> isPrimary,
      Value<int> rowid,
    });
typedef $$ProductBarcodesTableUpdateCompanionBuilder =
    ProductBarcodesCompanion Function({
      Value<String> barcode,
      Value<String> productId,
      Value<bool> isPrimary,
      Value<int> rowid,
    });

class $$ProductBarcodesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductBarcodesTable> {
  $$ProductBarcodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductBarcodesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductBarcodesTable> {
  $$ProductBarcodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductBarcodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductBarcodesTable> {
  $$ProductBarcodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);
}

class $$ProductBarcodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductBarcodesTable,
          ProductBarcode,
          $$ProductBarcodesTableFilterComposer,
          $$ProductBarcodesTableOrderingComposer,
          $$ProductBarcodesTableAnnotationComposer,
          $$ProductBarcodesTableCreateCompanionBuilder,
          $$ProductBarcodesTableUpdateCompanionBuilder,
          (
            ProductBarcode,
            BaseReferences<
              _$AppDatabase,
              $ProductBarcodesTable,
              ProductBarcode
            >,
          ),
          ProductBarcode,
          PrefetchHooks Function()
        > {
  $$ProductBarcodesTableTableManager(
    _$AppDatabase db,
    $ProductBarcodesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductBarcodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductBarcodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductBarcodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> barcode = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductBarcodesCompanion(
                barcode: barcode,
                productId: productId,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String barcode,
                required String productId,
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductBarcodesCompanion.insert(
                barcode: barcode,
                productId: productId,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductBarcodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductBarcodesTable,
      ProductBarcode,
      $$ProductBarcodesTableFilterComposer,
      $$ProductBarcodesTableOrderingComposer,
      $$ProductBarcodesTableAnnotationComposer,
      $$ProductBarcodesTableCreateCompanionBuilder,
      $$ProductBarcodesTableUpdateCompanionBuilder,
      (
        ProductBarcode,
        BaseReferences<_$AppDatabase, $ProductBarcodesTable, ProductBarcode>,
      ),
      ProductBarcode,
      PrefetchHooks Function()
    >;
typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      required String id,
      required String fullName,
      Value<String> phone,
      Value<String> note,
      Value<int?> debtLimitTiyin,
      Value<int> balanceTiyin,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<String> id,
      Value<String> fullName,
      Value<String> phone,
      Value<String> note,
      Value<int?> debtLimitTiyin,
      Value<int> balanceTiyin,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get debtLimitTiyin => $composableBuilder(
    column: $table.debtLimitTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceTiyin => $composableBuilder(
    column: $table.balanceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get debtLimitTiyin => $composableBuilder(
    column: $table.debtLimitTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceTiyin => $composableBuilder(
    column: $table.balanceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get debtLimitTiyin => $composableBuilder(
    column: $table.debtLimitTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get balanceTiyin => $composableBuilder(
    column: $table.balanceTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          Customer,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
          Customer,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int?> debtLimitTiyin = const Value.absent(),
                Value<int> balanceTiyin = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                fullName: fullName,
                phone: phone,
                note: note,
                debtLimitTiyin: debtLimitTiyin,
                balanceTiyin: balanceTiyin,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fullName,
                Value<String> phone = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int?> debtLimitTiyin = const Value.absent(),
                Value<int> balanceTiyin = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                fullName: fullName,
                phone: phone,
                note: note,
                debtLimitTiyin: debtLimitTiyin,
                balanceTiyin: balanceTiyin,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      Customer,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
      Customer,
      PrefetchHooks Function()
    >;
typedef $$SuppliersTableCreateCompanionBuilder =
    SuppliersCompanion Function({
      required String id,
      required String name,
      Value<String> phone,
      Value<String> note,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SuppliersTableUpdateCompanionBuilder =
    SuppliersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> phone,
      Value<String> note,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$SuppliersTableFilterComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SuppliersTableOrderingComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SuppliersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SuppliersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuppliersTable,
          Supplier,
          $$SuppliersTableFilterComposer,
          $$SuppliersTableOrderingComposer,
          $$SuppliersTableAnnotationComposer,
          $$SuppliersTableCreateCompanionBuilder,
          $$SuppliersTableUpdateCompanionBuilder,
          (Supplier, BaseReferences<_$AppDatabase, $SuppliersTable, Supplier>),
          Supplier,
          PrefetchHooks Function()
        > {
  $$SuppliersTableTableManager(_$AppDatabase db, $SuppliersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuppliersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuppliersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuppliersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuppliersCompanion(
                id: id,
                name: name,
                phone: phone,
                note: note,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> phone = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuppliersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                note: note,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SuppliersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuppliersTable,
      Supplier,
      $$SuppliersTableFilterComposer,
      $$SuppliersTableOrderingComposer,
      $$SuppliersTableAnnotationComposer,
      $$SuppliersTableCreateCompanionBuilder,
      $$SuppliersTableUpdateCompanionBuilder,
      (Supplier, BaseReferences<_$AppDatabase, $SuppliersTable, Supplier>),
      Supplier,
      PrefetchHooks Function()
    >;
typedef $$ProductStockTableCreateCompanionBuilder =
    ProductStockCompanion Function({
      required String productId,
      required String storeId,
      required int qtyMilli,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProductStockTableUpdateCompanionBuilder =
    ProductStockCompanion Function({
      Value<String> productId,
      Value<String> storeId,
      Value<int> qtyMilli,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProductStockTableFilterComposer
    extends Composer<_$AppDatabase, $ProductStockTable> {
  $$ProductStockTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductStockTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductStockTable> {
  $$ProductStockTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductStockTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductStockTable> {
  $$ProductStockTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<int> get qtyMilli =>
      $composableBuilder(column: $table.qtyMilli, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductStockTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductStockTable,
          ProductStockData,
          $$ProductStockTableFilterComposer,
          $$ProductStockTableOrderingComposer,
          $$ProductStockTableAnnotationComposer,
          $$ProductStockTableCreateCompanionBuilder,
          $$ProductStockTableUpdateCompanionBuilder,
          (
            ProductStockData,
            BaseReferences<_$AppDatabase, $ProductStockTable, ProductStockData>,
          ),
          ProductStockData,
          PrefetchHooks Function()
        > {
  $$ProductStockTableTableManager(_$AppDatabase db, $ProductStockTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductStockTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductStockTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductStockTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<int> qtyMilli = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductStockCompanion(
                productId: productId,
                storeId: storeId,
                qtyMilli: qtyMilli,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required String storeId,
                required int qtyMilli,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductStockCompanion.insert(
                productId: productId,
                storeId: storeId,
                qtyMilli: qtyMilli,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductStockTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductStockTable,
      ProductStockData,
      $$ProductStockTableFilterComposer,
      $$ProductStockTableOrderingComposer,
      $$ProductStockTableAnnotationComposer,
      $$ProductStockTableCreateCompanionBuilder,
      $$ProductStockTableUpdateCompanionBuilder,
      (
        ProductStockData,
        BaseReferences<_$AppDatabase, $ProductStockTable, ProductStockData>,
      ),
      ProductStockData,
      PrefetchHooks Function()
    >;
typedef $$DebtEntriesTableCreateCompanionBuilder =
    DebtEntriesCompanion Function({
      required String id,
      required String customerId,
      required int amountTiyin,
      required String type,
      Value<String?> saleId,
      Value<String?> refundId,
      Value<String?> shiftId,
      Value<String?> method,
      Value<String> note,
      Value<String?> byUserId,
      required DateTime at,
      Value<int> rowid,
    });
typedef $$DebtEntriesTableUpdateCompanionBuilder =
    DebtEntriesCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<int> amountTiyin,
      Value<String> type,
      Value<String?> saleId,
      Value<String?> refundId,
      Value<String?> shiftId,
      Value<String?> method,
      Value<String> note,
      Value<String?> byUserId,
      Value<DateTime> at,
      Value<int> rowid,
    });

class $$DebtEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DebtEntriesTable> {
  $$DebtEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refundId => $composableBuilder(
    column: $table.refundId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get byUserId => $composableBuilder(
    column: $table.byUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DebtEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtEntriesTable> {
  $$DebtEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refundId => $composableBuilder(
    column: $table.refundId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get byUserId => $composableBuilder(
    column: $table.byUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtEntriesTable> {
  $$DebtEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get refundId =>
      $composableBuilder(column: $table.refundId, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get byUserId =>
      $composableBuilder(column: $table.byUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$DebtEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtEntriesTable,
          DebtEntry,
          $$DebtEntriesTableFilterComposer,
          $$DebtEntriesTableOrderingComposer,
          $$DebtEntriesTableAnnotationComposer,
          $$DebtEntriesTableCreateCompanionBuilder,
          $$DebtEntriesTableUpdateCompanionBuilder,
          (
            DebtEntry,
            BaseReferences<_$AppDatabase, $DebtEntriesTable, DebtEntry>,
          ),
          DebtEntry,
          PrefetchHooks Function()
        > {
  $$DebtEntriesTableTableManager(_$AppDatabase db, $DebtEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<int> amountTiyin = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> saleId = const Value.absent(),
                Value<String?> refundId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<String?> method = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> byUserId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtEntriesCompanion(
                id: id,
                customerId: customerId,
                amountTiyin: amountTiyin,
                type: type,
                saleId: saleId,
                refundId: refundId,
                shiftId: shiftId,
                method: method,
                note: note,
                byUserId: byUserId,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required int amountTiyin,
                required String type,
                Value<String?> saleId = const Value.absent(),
                Value<String?> refundId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<String?> method = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> byUserId = const Value.absent(),
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => DebtEntriesCompanion.insert(
                id: id,
                customerId: customerId,
                amountTiyin: amountTiyin,
                type: type,
                saleId: saleId,
                refundId: refundId,
                shiftId: shiftId,
                method: method,
                note: note,
                byUserId: byUserId,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DebtEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtEntriesTable,
      DebtEntry,
      $$DebtEntriesTableFilterComposer,
      $$DebtEntriesTableOrderingComposer,
      $$DebtEntriesTableAnnotationComposer,
      $$DebtEntriesTableCreateCompanionBuilder,
      $$DebtEntriesTableUpdateCompanionBuilder,
      (DebtEntry, BaseReferences<_$AppDatabase, $DebtEntriesTable, DebtEntry>),
      DebtEntry,
      PrefetchHooks Function()
    >;
typedef $$ShiftsTableCreateCompanionBuilder =
    ShiftsCompanion Function({
      required String id,
      required String storeId,
      required String deviceId,
      required String openedBy,
      required DateTime openedAt,
      required int openingCashTiyin,
      Value<String?> closedBy,
      Value<DateTime?> closedAt,
      Value<int?> countedCashTiyin,
      Value<int?> expectedCashTiyin,
      Value<int> rowid,
    });
typedef $$ShiftsTableUpdateCompanionBuilder =
    ShiftsCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> deviceId,
      Value<String> openedBy,
      Value<DateTime> openedAt,
      Value<int> openingCashTiyin,
      Value<String?> closedBy,
      Value<DateTime?> closedAt,
      Value<int?> countedCashTiyin,
      Value<int?> expectedCashTiyin,
      Value<int> rowid,
    });

final class $$ShiftsTableReferences
    extends BaseReferences<_$AppDatabase, $ShiftsTable, Shift> {
  $$ShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sales,
    aliasName: $_aliasNameGenerator(db.shifts.id, db.sales.shiftId),
  );

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RefundsTable, List<Refund>> _refundsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.refunds,
    aliasName: $_aliasNameGenerator(db.shifts.id, db.refunds.shiftId),
  );

  $$RefundsTableProcessedTableManager get refundsRefs {
    final manager = $$RefundsTableTableManager(
      $_db,
      $_db.refunds,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CashMovementsTable, List<CashMovement>>
  _cashMovementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cashMovements,
    aliasName: $_aliasNameGenerator(db.shifts.id, db.cashMovements.shiftId),
  );

  $$CashMovementsTableProcessedTableManager get cashMovementsRefs {
    final manager = $$CashMovementsTableTableManager(
      $_db,
      $_db.cashMovements,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cashMovementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShiftsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedBy => $composableBuilder(
    column: $table.openedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingCashTiyin => $composableBuilder(
    column: $table.openingCashTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countedCashTiyin => $composableBuilder(
    column: $table.countedCashTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedCashTiyin => $composableBuilder(
    column: $table.expectedCashTiyin,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> salesRefs(
    Expression<bool> Function($$SalesTableFilterComposer f) f,
  ) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> refundsRefs(
    Expression<bool> Function($$RefundsTableFilterComposer f) f,
  ) {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refunds,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableFilterComposer(
            $db: $db,
            $table: $db.refunds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cashMovementsRefs(
    Expression<bool> Function($$CashMovementsTableFilterComposer f) f,
  ) {
    final $$CashMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashMovements,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashMovementsTableFilterComposer(
            $db: $db,
            $table: $db.cashMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedBy => $composableBuilder(
    column: $table.openedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingCashTiyin => $composableBuilder(
    column: $table.openingCashTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedBy => $composableBuilder(
    column: $table.closedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countedCashTiyin => $composableBuilder(
    column: $table.countedCashTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedCashTiyin => $composableBuilder(
    column: $table.expectedCashTiyin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShiftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get openedBy =>
      $composableBuilder(column: $table.openedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<int> get openingCashTiyin => $composableBuilder(
    column: $table.openingCashTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closedBy =>
      $composableBuilder(column: $table.closedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get countedCashTiyin => $composableBuilder(
    column: $table.countedCashTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedCashTiyin => $composableBuilder(
    column: $table.expectedCashTiyin,
    builder: (column) => column,
  );

  Expression<T> salesRefs<T extends Object>(
    Expression<T> Function($$SalesTableAnnotationComposer a) f,
  ) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> refundsRefs<T extends Object>(
    Expression<T> Function($$RefundsTableAnnotationComposer a) f,
  ) {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refunds,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableAnnotationComposer(
            $db: $db,
            $table: $db.refunds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cashMovementsRefs<T extends Object>(
    Expression<T> Function($$CashMovementsTableAnnotationComposer a) f,
  ) {
    final $$CashMovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashMovements,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashMovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.cashMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftsTable,
          Shift,
          $$ShiftsTableFilterComposer,
          $$ShiftsTableOrderingComposer,
          $$ShiftsTableAnnotationComposer,
          $$ShiftsTableCreateCompanionBuilder,
          $$ShiftsTableUpdateCompanionBuilder,
          (Shift, $$ShiftsTableReferences),
          Shift,
          PrefetchHooks Function({
            bool salesRefs,
            bool refundsRefs,
            bool cashMovementsRefs,
          })
        > {
  $$ShiftsTableTableManager(_$AppDatabase db, $ShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> openedBy = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<int> openingCashTiyin = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int?> countedCashTiyin = const Value.absent(),
                Value<int?> expectedCashTiyin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftsCompanion(
                id: id,
                storeId: storeId,
                deviceId: deviceId,
                openedBy: openedBy,
                openedAt: openedAt,
                openingCashTiyin: openingCashTiyin,
                closedBy: closedBy,
                closedAt: closedAt,
                countedCashTiyin: countedCashTiyin,
                expectedCashTiyin: expectedCashTiyin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String deviceId,
                required String openedBy,
                required DateTime openedAt,
                required int openingCashTiyin,
                Value<String?> closedBy = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int?> countedCashTiyin = const Value.absent(),
                Value<int?> expectedCashTiyin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftsCompanion.insert(
                id: id,
                storeId: storeId,
                deviceId: deviceId,
                openedBy: openedBy,
                openedAt: openedAt,
                openingCashTiyin: openingCashTiyin,
                closedBy: closedBy,
                closedAt: closedAt,
                countedCashTiyin: countedCashTiyin,
                expectedCashTiyin: expectedCashTiyin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ShiftsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                salesRefs = false,
                refundsRefs = false,
                cashMovementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (salesRefs) db.sales,
                    if (refundsRefs) db.refunds,
                    if (cashMovementsRefs) db.cashMovements,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (salesRefs)
                        await $_getPrefetchedData<Shift, $ShiftsTable, Sale>(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._salesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(db, table, p0).salesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shiftId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (refundsRefs)
                        await $_getPrefetchedData<Shift, $ShiftsTable, Refund>(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._refundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(
                                db,
                                table,
                                p0,
                              ).refundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shiftId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cashMovementsRefs)
                        await $_getPrefetchedData<
                          Shift,
                          $ShiftsTable,
                          CashMovement
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._cashMovementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(
                                db,
                                table,
                                p0,
                              ).cashMovementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shiftId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftsTable,
      Shift,
      $$ShiftsTableFilterComposer,
      $$ShiftsTableOrderingComposer,
      $$ShiftsTableAnnotationComposer,
      $$ShiftsTableCreateCompanionBuilder,
      $$ShiftsTableUpdateCompanionBuilder,
      (Shift, $$ShiftsTableReferences),
      Shift,
      PrefetchHooks Function({
        bool salesRefs,
        bool refundsRefs,
        bool cashMovementsRefs,
      })
    >;
typedef $$SalesTableCreateCompanionBuilder =
    SalesCompanion Function({
      required String id,
      required String shiftId,
      required String cashierId,
      Value<String?> customerId,
      Value<String?> approvedBy,
      required String number,
      required int subtotalTiyin,
      required int discountTiyin,
      required int totalTiyin,
      Value<String> status,
      Value<String?> debtEntryId,
      required DateTime soldAt,
      Value<int> rowid,
    });
typedef $$SalesTableUpdateCompanionBuilder =
    SalesCompanion Function({
      Value<String> id,
      Value<String> shiftId,
      Value<String> cashierId,
      Value<String?> customerId,
      Value<String?> approvedBy,
      Value<String> number,
      Value<int> subtotalTiyin,
      Value<int> discountTiyin,
      Value<int> totalTiyin,
      Value<String> status,
      Value<String?> debtEntryId,
      Value<DateTime> soldAt,
      Value<int> rowid,
    });

final class $$SalesTableReferences
    extends BaseReferences<_$AppDatabase, $SalesTable, Sale> {
  $$SalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) => db.shifts.createAlias(
    $_aliasNameGenerator(db.sales.shiftId, db.shifts.id),
  );

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<String>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SaleItemsTable, List<SaleItem>>
  _saleItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleItems,
    aliasName: $_aliasNameGenerator(db.sales.id, db.saleItems.saleId),
  );

  $$SaleItemsTableProcessedTableManager get saleItemsRefs {
    final manager = $$SaleItemsTableTableManager(
      $_db,
      $_db.saleItems,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SalePaymentsTable, List<SalePayment>>
  _salePaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.salePayments,
    aliasName: $_aliasNameGenerator(db.sales.id, db.salePayments.saleId),
  );

  $$SalePaymentsTableProcessedTableManager get salePaymentsRefs {
    final manager = $$SalePaymentsTableTableManager(
      $_db,
      $_db.salePayments,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_salePaymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalTiyin => $composableBuilder(
    column: $table.subtotalTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountTiyin => $composableBuilder(
    column: $table.discountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get soldAt => $composableBuilder(
    column: $table.soldAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> saleItemsRefs(
    Expression<bool> Function($$SaleItemsTableFilterComposer f) f,
  ) {
    final $$SaleItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItems,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableFilterComposer(
            $db: $db,
            $table: $db.saleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> salePaymentsRefs(
    Expression<bool> Function($$SalePaymentsTableFilterComposer f) f,
  ) {
    final $$SalePaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.salePayments,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalePaymentsTableFilterComposer(
            $db: $db,
            $table: $db.salePayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalTiyin => $composableBuilder(
    column: $table.subtotalTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountTiyin => $composableBuilder(
    column: $table.discountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get soldAt => $composableBuilder(
    column: $table.soldAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get subtotalTiyin => $composableBuilder(
    column: $table.subtotalTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountTiyin => $composableBuilder(
    column: $table.discountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get soldAt =>
      $composableBuilder(column: $table.soldAt, builder: (column) => column);

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> saleItemsRefs<T extends Object>(
    Expression<T> Function($$SaleItemsTableAnnotationComposer a) f,
  ) {
    final $$SaleItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItems,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> salePaymentsRefs<T extends Object>(
    Expression<T> Function($$SalePaymentsTableAnnotationComposer a) f,
  ) {
    final $$SalePaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.salePayments,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalePaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.salePayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTable,
          Sale,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (Sale, $$SalesTableReferences),
          Sale,
          PrefetchHooks Function({
            bool shiftId,
            bool saleItemsRefs,
            bool salePaymentsRefs,
          })
        > {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<int> subtotalTiyin = const Value.absent(),
                Value<int> discountTiyin = const Value.absent(),
                Value<int> totalTiyin = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> debtEntryId = const Value.absent(),
                Value<DateTime> soldAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion(
                id: id,
                shiftId: shiftId,
                cashierId: cashierId,
                customerId: customerId,
                approvedBy: approvedBy,
                number: number,
                subtotalTiyin: subtotalTiyin,
                discountTiyin: discountTiyin,
                totalTiyin: totalTiyin,
                status: status,
                debtEntryId: debtEntryId,
                soldAt: soldAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shiftId,
                required String cashierId,
                Value<String?> customerId = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                required String number,
                required int subtotalTiyin,
                required int discountTiyin,
                required int totalTiyin,
                Value<String> status = const Value.absent(),
                Value<String?> debtEntryId = const Value.absent(),
                required DateTime soldAt,
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion.insert(
                id: id,
                shiftId: shiftId,
                cashierId: cashierId,
                customerId: customerId,
                approvedBy: approvedBy,
                number: number,
                subtotalTiyin: subtotalTiyin,
                discountTiyin: discountTiyin,
                totalTiyin: totalTiyin,
                status: status,
                debtEntryId: debtEntryId,
                soldAt: soldAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SalesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                shiftId = false,
                saleItemsRefs = false,
                salePaymentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (saleItemsRefs) db.saleItems,
                    if (salePaymentsRefs) db.salePayments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (shiftId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.shiftId,
                                    referencedTable: $$SalesTableReferences
                                        ._shiftIdTable(db),
                                    referencedColumn: $$SalesTableReferences
                                        ._shiftIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (saleItemsRefs)
                        await $_getPrefetchedData<Sale, $SalesTable, SaleItem>(
                          currentTable: table,
                          referencedTable: $$SalesTableReferences
                              ._saleItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SalesTableReferences(
                                db,
                                table,
                                p0,
                              ).saleItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (salePaymentsRefs)
                        await $_getPrefetchedData<
                          Sale,
                          $SalesTable,
                          SalePayment
                        >(
                          currentTable: table,
                          referencedTable: $$SalesTableReferences
                              ._salePaymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SalesTableReferences(
                                db,
                                table,
                                p0,
                              ).salePaymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTable,
      Sale,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (Sale, $$SalesTableReferences),
      Sale,
      PrefetchHooks Function({
        bool shiftId,
        bool saleItemsRefs,
        bool salePaymentsRefs,
      })
    >;
typedef $$SaleItemsTableCreateCompanionBuilder =
    SaleItemsCompanion Function({
      required String id,
      required String saleId,
      required int position,
      required String productId,
      required String nameSnapshot,
      Value<String?> barcodeSnapshot,
      required int qtyMilli,
      required int priceTiyin,
      required int costTiyin,
      required int discountTiyin,
      required int totalTiyin,
      Value<int> rowid,
    });
typedef $$SaleItemsTableUpdateCompanionBuilder =
    SaleItemsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<int> position,
      Value<String> productId,
      Value<String> nameSnapshot,
      Value<String?> barcodeSnapshot,
      Value<int> qtyMilli,
      Value<int> priceTiyin,
      Value<int> costTiyin,
      Value<int> discountTiyin,
      Value<int> totalTiyin,
      Value<int> rowid,
    });

final class $$SaleItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SaleItemsTable, SaleItem> {
  $$SaleItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$AppDatabase db) => db.sales.createAlias(
    $_aliasNameGenerator(db.saleItems.saleId, db.sales.id),
  );

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<String>('sale_id')!;

    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SaleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeSnapshot => $composableBuilder(
    column: $table.barcodeSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceTiyin => $composableBuilder(
    column: $table.priceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costTiyin => $composableBuilder(
    column: $table.costTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountTiyin => $composableBuilder(
    column: $table.discountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeSnapshot => $composableBuilder(
    column: $table.barcodeSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceTiyin => $composableBuilder(
    column: $table.priceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costTiyin => $composableBuilder(
    column: $table.costTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountTiyin => $composableBuilder(
    column: $table.discountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableOrderingComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcodeSnapshot => $composableBuilder(
    column: $table.barcodeSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qtyMilli =>
      $composableBuilder(column: $table.qtyMilli, builder: (column) => column);

  GeneratedColumn<int> get priceTiyin => $composableBuilder(
    column: $table.priceTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costTiyin =>
      $composableBuilder(column: $table.costTiyin, builder: (column) => column);

  GeneratedColumn<int> get discountTiyin => $composableBuilder(
    column: $table.discountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => column,
  );

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleItemsTable,
          SaleItem,
          $$SaleItemsTableFilterComposer,
          $$SaleItemsTableOrderingComposer,
          $$SaleItemsTableAnnotationComposer,
          $$SaleItemsTableCreateCompanionBuilder,
          $$SaleItemsTableUpdateCompanionBuilder,
          (SaleItem, $$SaleItemsTableReferences),
          SaleItem,
          PrefetchHooks Function({bool saleId})
        > {
  $$SaleItemsTableTableManager(_$AppDatabase db, $SaleItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> nameSnapshot = const Value.absent(),
                Value<String?> barcodeSnapshot = const Value.absent(),
                Value<int> qtyMilli = const Value.absent(),
                Value<int> priceTiyin = const Value.absent(),
                Value<int> costTiyin = const Value.absent(),
                Value<int> discountTiyin = const Value.absent(),
                Value<int> totalTiyin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaleItemsCompanion(
                id: id,
                saleId: saleId,
                position: position,
                productId: productId,
                nameSnapshot: nameSnapshot,
                barcodeSnapshot: barcodeSnapshot,
                qtyMilli: qtyMilli,
                priceTiyin: priceTiyin,
                costTiyin: costTiyin,
                discountTiyin: discountTiyin,
                totalTiyin: totalTiyin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                required int position,
                required String productId,
                required String nameSnapshot,
                Value<String?> barcodeSnapshot = const Value.absent(),
                required int qtyMilli,
                required int priceTiyin,
                required int costTiyin,
                required int discountTiyin,
                required int totalTiyin,
                Value<int> rowid = const Value.absent(),
              }) => SaleItemsCompanion.insert(
                id: id,
                saleId: saleId,
                position: position,
                productId: productId,
                nameSnapshot: nameSnapshot,
                barcodeSnapshot: barcodeSnapshot,
                qtyMilli: qtyMilli,
                priceTiyin: priceTiyin,
                costTiyin: costTiyin,
                discountTiyin: discountTiyin,
                totalTiyin: totalTiyin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SaleItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleId,
                                referencedTable: $$SaleItemsTableReferences
                                    ._saleIdTable(db),
                                referencedColumn: $$SaleItemsTableReferences
                                    ._saleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SaleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleItemsTable,
      SaleItem,
      $$SaleItemsTableFilterComposer,
      $$SaleItemsTableOrderingComposer,
      $$SaleItemsTableAnnotationComposer,
      $$SaleItemsTableCreateCompanionBuilder,
      $$SaleItemsTableUpdateCompanionBuilder,
      (SaleItem, $$SaleItemsTableReferences),
      SaleItem,
      PrefetchHooks Function({bool saleId})
    >;
typedef $$SalePaymentsTableCreateCompanionBuilder =
    SalePaymentsCompanion Function({
      required String id,
      required String saleId,
      required String method,
      required int amountTiyin,
      Value<int?> receivedTiyin,
      Value<int> changeTiyin,
      Value<int> rowid,
    });
typedef $$SalePaymentsTableUpdateCompanionBuilder =
    SalePaymentsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String> method,
      Value<int> amountTiyin,
      Value<int?> receivedTiyin,
      Value<int> changeTiyin,
      Value<int> rowid,
    });

final class $$SalePaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $SalePaymentsTable, SalePayment> {
  $$SalePaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$AppDatabase db) => db.sales.createAlias(
    $_aliasNameGenerator(db.salePayments.saleId, db.sales.id),
  );

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<String>('sale_id')!;

    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SalePaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedTiyin => $composableBuilder(
    column: $table.receivedTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeTiyin => $composableBuilder(
    column: $table.changeTiyin,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalePaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedTiyin => $composableBuilder(
    column: $table.receivedTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeTiyin => $composableBuilder(
    column: $table.changeTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableOrderingComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalePaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedTiyin => $composableBuilder(
    column: $table.receivedTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get changeTiyin => $composableBuilder(
    column: $table.changeTiyin,
    builder: (column) => column,
  );

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalePaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalePaymentsTable,
          SalePayment,
          $$SalePaymentsTableFilterComposer,
          $$SalePaymentsTableOrderingComposer,
          $$SalePaymentsTableAnnotationComposer,
          $$SalePaymentsTableCreateCompanionBuilder,
          $$SalePaymentsTableUpdateCompanionBuilder,
          (SalePayment, $$SalePaymentsTableReferences),
          SalePayment,
          PrefetchHooks Function({bool saleId})
        > {
  $$SalePaymentsTableTableManager(_$AppDatabase db, $SalePaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalePaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalePaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalePaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> amountTiyin = const Value.absent(),
                Value<int?> receivedTiyin = const Value.absent(),
                Value<int> changeTiyin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalePaymentsCompanion(
                id: id,
                saleId: saleId,
                method: method,
                amountTiyin: amountTiyin,
                receivedTiyin: receivedTiyin,
                changeTiyin: changeTiyin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                required String method,
                required int amountTiyin,
                Value<int?> receivedTiyin = const Value.absent(),
                Value<int> changeTiyin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalePaymentsCompanion.insert(
                id: id,
                saleId: saleId,
                method: method,
                amountTiyin: amountTiyin,
                receivedTiyin: receivedTiyin,
                changeTiyin: changeTiyin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SalePaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleId,
                                referencedTable: $$SalePaymentsTableReferences
                                    ._saleIdTable(db),
                                referencedColumn: $$SalePaymentsTableReferences
                                    ._saleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SalePaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalePaymentsTable,
      SalePayment,
      $$SalePaymentsTableFilterComposer,
      $$SalePaymentsTableOrderingComposer,
      $$SalePaymentsTableAnnotationComposer,
      $$SalePaymentsTableCreateCompanionBuilder,
      $$SalePaymentsTableUpdateCompanionBuilder,
      (SalePayment, $$SalePaymentsTableReferences),
      SalePayment,
      PrefetchHooks Function({bool saleId})
    >;
typedef $$RefundsTableCreateCompanionBuilder =
    RefundsCompanion Function({
      required String id,
      required String saleId,
      required String shiftId,
      required String cashierId,
      Value<String?> approvedBy,
      Value<String> reason,
      required String method,
      required int totalTiyin,
      Value<String?> debtEntryId,
      required DateTime at,
      Value<int> rowid,
    });
typedef $$RefundsTableUpdateCompanionBuilder =
    RefundsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String> shiftId,
      Value<String> cashierId,
      Value<String?> approvedBy,
      Value<String> reason,
      Value<String> method,
      Value<int> totalTiyin,
      Value<String?> debtEntryId,
      Value<DateTime> at,
      Value<int> rowid,
    });

final class $$RefundsTableReferences
    extends BaseReferences<_$AppDatabase, $RefundsTable, Refund> {
  $$RefundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) => db.shifts.createAlias(
    $_aliasNameGenerator(db.refunds.shiftId, db.shifts.id),
  );

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<String>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RefundItemsTable, List<RefundItem>>
  _refundItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.refundItems,
    aliasName: $_aliasNameGenerator(db.refunds.id, db.refundItems.refundId),
  );

  $$RefundItemsTableProcessedTableManager get refundItemsRefs {
    final manager = $$RefundItemsTableTableManager(
      $_db,
      $_db.refundItems,
    ).filter((f) => f.refundId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RefundsTableFilterComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> refundItemsRefs(
    Expression<bool> Function($$RefundItemsTableFilterComposer f) f,
  ) {
    final $$RefundItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refundItems,
      getReferencedColumn: (t) => t.refundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundItemsTableFilterComposer(
            $db: $db,
            $table: $db.refundItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RefundsTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> refundItemsRefs<T extends Object>(
    Expression<T> Function($$RefundItemsTableAnnotationComposer a) f,
  ) {
    final $$RefundItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refundItems,
      getReferencedColumn: (t) => t.refundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.refundItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RefundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefundsTable,
          Refund,
          $$RefundsTableFilterComposer,
          $$RefundsTableOrderingComposer,
          $$RefundsTableAnnotationComposer,
          $$RefundsTableCreateCompanionBuilder,
          $$RefundsTableUpdateCompanionBuilder,
          (Refund, $$RefundsTableReferences),
          Refund,
          PrefetchHooks Function({bool shiftId, bool refundItemsRefs})
        > {
  $$RefundsTableTableManager(_$AppDatabase db, $RefundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> totalTiyin = const Value.absent(),
                Value<String?> debtEntryId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefundsCompanion(
                id: id,
                saleId: saleId,
                shiftId: shiftId,
                cashierId: cashierId,
                approvedBy: approvedBy,
                reason: reason,
                method: method,
                totalTiyin: totalTiyin,
                debtEntryId: debtEntryId,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                required String shiftId,
                required String cashierId,
                Value<String?> approvedBy = const Value.absent(),
                Value<String> reason = const Value.absent(),
                required String method,
                required int totalTiyin,
                Value<String?> debtEntryId = const Value.absent(),
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => RefundsCompanion.insert(
                id: id,
                saleId: saleId,
                shiftId: shiftId,
                cashierId: cashierId,
                approvedBy: approvedBy,
                reason: reason,
                method: method,
                totalTiyin: totalTiyin,
                debtEntryId: debtEntryId,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RefundsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shiftId = false, refundItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (refundItemsRefs) db.refundItems],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shiftId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shiftId,
                                referencedTable: $$RefundsTableReferences
                                    ._shiftIdTable(db),
                                referencedColumn: $$RefundsTableReferences
                                    ._shiftIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (refundItemsRefs)
                    await $_getPrefetchedData<
                      Refund,
                      $RefundsTable,
                      RefundItem
                    >(
                      currentTable: table,
                      referencedTable: $$RefundsTableReferences
                          ._refundItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RefundsTableReferences(
                        db,
                        table,
                        p0,
                      ).refundItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.refundId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RefundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefundsTable,
      Refund,
      $$RefundsTableFilterComposer,
      $$RefundsTableOrderingComposer,
      $$RefundsTableAnnotationComposer,
      $$RefundsTableCreateCompanionBuilder,
      $$RefundsTableUpdateCompanionBuilder,
      (Refund, $$RefundsTableReferences),
      Refund,
      PrefetchHooks Function({bool shiftId, bool refundItemsRefs})
    >;
typedef $$RefundItemsTableCreateCompanionBuilder =
    RefundItemsCompanion Function({
      required String id,
      required String refundId,
      required String saleItemId,
      required int qtyMilli,
      required int totalTiyin,
      Value<int> rowid,
    });
typedef $$RefundItemsTableUpdateCompanionBuilder =
    RefundItemsCompanion Function({
      Value<String> id,
      Value<String> refundId,
      Value<String> saleItemId,
      Value<int> qtyMilli,
      Value<int> totalTiyin,
      Value<int> rowid,
    });

final class $$RefundItemsTableReferences
    extends BaseReferences<_$AppDatabase, $RefundItemsTable, RefundItem> {
  $$RefundItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RefundsTable _refundIdTable(_$AppDatabase db) =>
      db.refunds.createAlias(
        $_aliasNameGenerator(db.refundItems.refundId, db.refunds.id),
      );

  $$RefundsTableProcessedTableManager get refundId {
    final $_column = $_itemColumn<String>('refund_id')!;

    final manager = $$RefundsTableTableManager(
      $_db,
      $_db.refunds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_refundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RefundItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RefundItemsTable> {
  $$RefundItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleItemId => $composableBuilder(
    column: $table.saleItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => ColumnFilters(column),
  );

  $$RefundsTableFilterComposer get refundId {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundId,
      referencedTable: $db.refunds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableFilterComposer(
            $db: $db,
            $table: $db.refunds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefundItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundItemsTable> {
  $$RefundItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleItemId => $composableBuilder(
    column: $table.saleItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  $$RefundsTableOrderingComposer get refundId {
    final $$RefundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundId,
      referencedTable: $db.refunds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableOrderingComposer(
            $db: $db,
            $table: $db.refunds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefundItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundItemsTable> {
  $$RefundItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleItemId => $composableBuilder(
    column: $table.saleItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qtyMilli =>
      $composableBuilder(column: $table.qtyMilli, builder: (column) => column);

  GeneratedColumn<int> get totalTiyin => $composableBuilder(
    column: $table.totalTiyin,
    builder: (column) => column,
  );

  $$RefundsTableAnnotationComposer get refundId {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundId,
      referencedTable: $db.refunds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableAnnotationComposer(
            $db: $db,
            $table: $db.refunds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefundItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefundItemsTable,
          RefundItem,
          $$RefundItemsTableFilterComposer,
          $$RefundItemsTableOrderingComposer,
          $$RefundItemsTableAnnotationComposer,
          $$RefundItemsTableCreateCompanionBuilder,
          $$RefundItemsTableUpdateCompanionBuilder,
          (RefundItem, $$RefundItemsTableReferences),
          RefundItem,
          PrefetchHooks Function({bool refundId})
        > {
  $$RefundItemsTableTableManager(_$AppDatabase db, $RefundItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefundItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefundItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefundItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> refundId = const Value.absent(),
                Value<String> saleItemId = const Value.absent(),
                Value<int> qtyMilli = const Value.absent(),
                Value<int> totalTiyin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefundItemsCompanion(
                id: id,
                refundId: refundId,
                saleItemId: saleItemId,
                qtyMilli: qtyMilli,
                totalTiyin: totalTiyin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String refundId,
                required String saleItemId,
                required int qtyMilli,
                required int totalTiyin,
                Value<int> rowid = const Value.absent(),
              }) => RefundItemsCompanion.insert(
                id: id,
                refundId: refundId,
                saleItemId: saleItemId,
                qtyMilli: qtyMilli,
                totalTiyin: totalTiyin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RefundItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({refundId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (refundId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.refundId,
                                referencedTable: $$RefundItemsTableReferences
                                    ._refundIdTable(db),
                                referencedColumn: $$RefundItemsTableReferences
                                    ._refundIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RefundItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefundItemsTable,
      RefundItem,
      $$RefundItemsTableFilterComposer,
      $$RefundItemsTableOrderingComposer,
      $$RefundItemsTableAnnotationComposer,
      $$RefundItemsTableCreateCompanionBuilder,
      $$RefundItemsTableUpdateCompanionBuilder,
      (RefundItem, $$RefundItemsTableReferences),
      RefundItem,
      PrefetchHooks Function({bool refundId})
    >;
typedef $$CashMovementsTableCreateCompanionBuilder =
    CashMovementsCompanion Function({
      required String id,
      required String shiftId,
      required String type,
      required int amountTiyin,
      Value<String> reason,
      required String byUserId,
      required DateTime at,
      Value<int> rowid,
    });
typedef $$CashMovementsTableUpdateCompanionBuilder =
    CashMovementsCompanion Function({
      Value<String> id,
      Value<String> shiftId,
      Value<String> type,
      Value<int> amountTiyin,
      Value<String> reason,
      Value<String> byUserId,
      Value<DateTime> at,
      Value<int> rowid,
    });

final class $$CashMovementsTableReferences
    extends BaseReferences<_$AppDatabase, $CashMovementsTable, CashMovement> {
  $$CashMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) => db.shifts.createAlias(
    $_aliasNameGenerator(db.cashMovements.shiftId, db.shifts.id),
  );

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<String>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CashMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get byUserId => $composableBuilder(
    column: $table.byUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get byUserId => $composableBuilder(
    column: $table.byUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountTiyin => $composableBuilder(
    column: $table.amountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get byUserId =>
      $composableBuilder(column: $table.byUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashMovementsTable,
          CashMovement,
          $$CashMovementsTableFilterComposer,
          $$CashMovementsTableOrderingComposer,
          $$CashMovementsTableAnnotationComposer,
          $$CashMovementsTableCreateCompanionBuilder,
          $$CashMovementsTableUpdateCompanionBuilder,
          (CashMovement, $$CashMovementsTableReferences),
          CashMovement,
          PrefetchHooks Function({bool shiftId})
        > {
  $$CashMovementsTableTableManager(_$AppDatabase db, $CashMovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountTiyin = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> byUserId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashMovementsCompanion(
                id: id,
                shiftId: shiftId,
                type: type,
                amountTiyin: amountTiyin,
                reason: reason,
                byUserId: byUserId,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shiftId,
                required String type,
                required int amountTiyin,
                Value<String> reason = const Value.absent(),
                required String byUserId,
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => CashMovementsCompanion.insert(
                id: id,
                shiftId: shiftId,
                type: type,
                amountTiyin: amountTiyin,
                reason: reason,
                byUserId: byUserId,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CashMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shiftId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shiftId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shiftId,
                                referencedTable: $$CashMovementsTableReferences
                                    ._shiftIdTable(db),
                                referencedColumn: $$CashMovementsTableReferences
                                    ._shiftIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CashMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashMovementsTable,
      CashMovement,
      $$CashMovementsTableFilterComposer,
      $$CashMovementsTableOrderingComposer,
      $$CashMovementsTableAnnotationComposer,
      $$CashMovementsTableCreateCompanionBuilder,
      $$CashMovementsTableUpdateCompanionBuilder,
      (CashMovement, $$CashMovementsTableReferences),
      CashMovement,
      PrefetchHooks Function({bool shiftId})
    >;
typedef $$StockReceiptsTableCreateCompanionBuilder =
    StockReceiptsCompanion Function({
      required String id,
      Value<String?> supplierId,
      Value<String?> storeId,
      Value<int?> number,
      Value<String> status,
      Value<int> totalCostTiyin,
      Value<String> note,
      required DateTime createdAt,
      Value<DateTime?> postedAt,
      Value<String?> postedBy,
      Value<String?> correctsId,
      Value<String?> reversesId,
      Value<int> rowid,
    });
typedef $$StockReceiptsTableUpdateCompanionBuilder =
    StockReceiptsCompanion Function({
      Value<String> id,
      Value<String?> supplierId,
      Value<String?> storeId,
      Value<int?> number,
      Value<String> status,
      Value<int> totalCostTiyin,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime?> postedAt,
      Value<String?> postedBy,
      Value<String?> correctsId,
      Value<String?> reversesId,
      Value<int> rowid,
    });

final class $$StockReceiptsTableReferences
    extends BaseReferences<_$AppDatabase, $StockReceiptsTable, StockReceipt> {
  $$StockReceiptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$StockReceiptItemsTable, List<StockReceiptItem>>
  _stockReceiptItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.stockReceiptItems,
        aliasName: $_aliasNameGenerator(
          db.stockReceipts.id,
          db.stockReceiptItems.receiptId,
        ),
      );

  $$StockReceiptItemsTableProcessedTableManager get stockReceiptItemsRefs {
    final manager = $$StockReceiptItemsTableTableManager(
      $_db,
      $_db.stockReceiptItems,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _stockReceiptItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StockReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $StockReceiptsTable> {
  $$StockReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCostTiyin => $composableBuilder(
    column: $table.totalCostTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postedBy => $composableBuilder(
    column: $table.postedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctsId => $composableBuilder(
    column: $table.correctsId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reversesId => $composableBuilder(
    column: $table.reversesId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stockReceiptItemsRefs(
    Expression<bool> Function($$StockReceiptItemsTableFilterComposer f) f,
  ) {
    final $$StockReceiptItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockReceiptItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockReceiptItemsTableFilterComposer(
            $db: $db,
            $table: $db.stockReceiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StockReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockReceiptsTable> {
  $$StockReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCostTiyin => $composableBuilder(
    column: $table.totalCostTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postedBy => $composableBuilder(
    column: $table.postedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctsId => $composableBuilder(
    column: $table.correctsId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reversesId => $composableBuilder(
    column: $table.reversesId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockReceiptsTable> {
  $$StockReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalCostTiyin => $composableBuilder(
    column: $table.totalCostTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<String> get postedBy =>
      $composableBuilder(column: $table.postedBy, builder: (column) => column);

  GeneratedColumn<String> get correctsId => $composableBuilder(
    column: $table.correctsId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reversesId => $composableBuilder(
    column: $table.reversesId,
    builder: (column) => column,
  );

  Expression<T> stockReceiptItemsRefs<T extends Object>(
    Expression<T> Function($$StockReceiptItemsTableAnnotationComposer a) f,
  ) {
    final $$StockReceiptItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.stockReceiptItems,
          getReferencedColumn: (t) => t.receiptId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StockReceiptItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.stockReceiptItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StockReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockReceiptsTable,
          StockReceipt,
          $$StockReceiptsTableFilterComposer,
          $$StockReceiptsTableOrderingComposer,
          $$StockReceiptsTableAnnotationComposer,
          $$StockReceiptsTableCreateCompanionBuilder,
          $$StockReceiptsTableUpdateCompanionBuilder,
          (StockReceipt, $$StockReceiptsTableReferences),
          StockReceipt,
          PrefetchHooks Function({bool stockReceiptItemsRefs})
        > {
  $$StockReceiptsTableTableManager(_$AppDatabase db, $StockReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalCostTiyin = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> postedAt = const Value.absent(),
                Value<String?> postedBy = const Value.absent(),
                Value<String?> correctsId = const Value.absent(),
                Value<String?> reversesId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockReceiptsCompanion(
                id: id,
                supplierId: supplierId,
                storeId: storeId,
                number: number,
                status: status,
                totalCostTiyin: totalCostTiyin,
                note: note,
                createdAt: createdAt,
                postedAt: postedAt,
                postedBy: postedBy,
                correctsId: correctsId,
                reversesId: reversesId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> supplierId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalCostTiyin = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> postedAt = const Value.absent(),
                Value<String?> postedBy = const Value.absent(),
                Value<String?> correctsId = const Value.absent(),
                Value<String?> reversesId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockReceiptsCompanion.insert(
                id: id,
                supplierId: supplierId,
                storeId: storeId,
                number: number,
                status: status,
                totalCostTiyin: totalCostTiyin,
                note: note,
                createdAt: createdAt,
                postedAt: postedAt,
                postedBy: postedBy,
                correctsId: correctsId,
                reversesId: reversesId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StockReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stockReceiptItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stockReceiptItemsRefs) db.stockReceiptItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockReceiptItemsRefs)
                    await $_getPrefetchedData<
                      StockReceipt,
                      $StockReceiptsTable,
                      StockReceiptItem
                    >(
                      currentTable: table,
                      referencedTable: $$StockReceiptsTableReferences
                          ._stockReceiptItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StockReceiptsTableReferences(
                            db,
                            table,
                            p0,
                          ).stockReceiptItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.receiptId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StockReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockReceiptsTable,
      StockReceipt,
      $$StockReceiptsTableFilterComposer,
      $$StockReceiptsTableOrderingComposer,
      $$StockReceiptsTableAnnotationComposer,
      $$StockReceiptsTableCreateCompanionBuilder,
      $$StockReceiptsTableUpdateCompanionBuilder,
      (StockReceipt, $$StockReceiptsTableReferences),
      StockReceipt,
      PrefetchHooks Function({bool stockReceiptItemsRefs})
    >;
typedef $$StockReceiptItemsTableCreateCompanionBuilder =
    StockReceiptItemsCompanion Function({
      required String id,
      required String receiptId,
      required int position,
      required String productId,
      required int qtyMilli,
      required int costPriceTiyin,
      Value<int?> newSellPriceTiyin,
      Value<int> rowid,
    });
typedef $$StockReceiptItemsTableUpdateCompanionBuilder =
    StockReceiptItemsCompanion Function({
      Value<String> id,
      Value<String> receiptId,
      Value<int> position,
      Value<String> productId,
      Value<int> qtyMilli,
      Value<int> costPriceTiyin,
      Value<int?> newSellPriceTiyin,
      Value<int> rowid,
    });

final class $$StockReceiptItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StockReceiptItemsTable,
          StockReceiptItem
        > {
  $$StockReceiptItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StockReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.stockReceipts.createAlias(
        $_aliasNameGenerator(
          db.stockReceiptItems.receiptId,
          db.stockReceipts.id,
        ),
      );

  $$StockReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<String>('receipt_id')!;

    final manager = $$StockReceiptsTableTableManager(
      $_db,
      $_db.stockReceipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockReceiptItemsTableFilterComposer
    extends Composer<_$AppDatabase, $StockReceiptItemsTable> {
  $$StockReceiptItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPriceTiyin => $composableBuilder(
    column: $table.costPriceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newSellPriceTiyin => $composableBuilder(
    column: $table.newSellPriceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  $$StockReceiptsTableFilterComposer get receiptId {
    final $$StockReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.stockReceipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.stockReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockReceiptItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockReceiptItemsTable> {
  $$StockReceiptItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPriceTiyin => $composableBuilder(
    column: $table.costPriceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newSellPriceTiyin => $composableBuilder(
    column: $table.newSellPriceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  $$StockReceiptsTableOrderingComposer get receiptId {
    final $$StockReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.stockReceipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.stockReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockReceiptItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockReceiptItemsTable> {
  $$StockReceiptItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get qtyMilli =>
      $composableBuilder(column: $table.qtyMilli, builder: (column) => column);

  GeneratedColumn<int> get costPriceTiyin => $composableBuilder(
    column: $table.costPriceTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newSellPriceTiyin => $composableBuilder(
    column: $table.newSellPriceTiyin,
    builder: (column) => column,
  );

  $$StockReceiptsTableAnnotationComposer get receiptId {
    final $$StockReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.stockReceipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.stockReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockReceiptItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockReceiptItemsTable,
          StockReceiptItem,
          $$StockReceiptItemsTableFilterComposer,
          $$StockReceiptItemsTableOrderingComposer,
          $$StockReceiptItemsTableAnnotationComposer,
          $$StockReceiptItemsTableCreateCompanionBuilder,
          $$StockReceiptItemsTableUpdateCompanionBuilder,
          (StockReceiptItem, $$StockReceiptItemsTableReferences),
          StockReceiptItem,
          PrefetchHooks Function({bool receiptId})
        > {
  $$StockReceiptItemsTableTableManager(
    _$AppDatabase db,
    $StockReceiptItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockReceiptItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockReceiptItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockReceiptItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> qtyMilli = const Value.absent(),
                Value<int> costPriceTiyin = const Value.absent(),
                Value<int?> newSellPriceTiyin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockReceiptItemsCompanion(
                id: id,
                receiptId: receiptId,
                position: position,
                productId: productId,
                qtyMilli: qtyMilli,
                costPriceTiyin: costPriceTiyin,
                newSellPriceTiyin: newSellPriceTiyin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptId,
                required int position,
                required String productId,
                required int qtyMilli,
                required int costPriceTiyin,
                Value<int?> newSellPriceTiyin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockReceiptItemsCompanion.insert(
                id: id,
                receiptId: receiptId,
                position: position,
                productId: productId,
                qtyMilli: qtyMilli,
                costPriceTiyin: costPriceTiyin,
                newSellPriceTiyin: newSellPriceTiyin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StockReceiptItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.receiptId,
                                referencedTable:
                                    $$StockReceiptItemsTableReferences
                                        ._receiptIdTable(db),
                                referencedColumn:
                                    $$StockReceiptItemsTableReferences
                                        ._receiptIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StockReceiptItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockReceiptItemsTable,
      StockReceiptItem,
      $$StockReceiptItemsTableFilterComposer,
      $$StockReceiptItemsTableOrderingComposer,
      $$StockReceiptItemsTableAnnotationComposer,
      $$StockReceiptItemsTableCreateCompanionBuilder,
      $$StockReceiptItemsTableUpdateCompanionBuilder,
      (StockReceiptItem, $$StockReceiptItemsTableReferences),
      StockReceiptItem,
      PrefetchHooks Function({bool receiptId})
    >;
typedef $$InventoryCountsTableCreateCompanionBuilder =
    InventoryCountsCompanion Function({
      required String id,
      Value<String?> storeId,
      Value<String> status,
      Value<String> scope,
      Value<String?> categoryId,
      Value<String> note,
      required DateTime createdAt,
      Value<DateTime?> postedAt,
      Value<String?> postedBy,
      Value<int> rowid,
    });
typedef $$InventoryCountsTableUpdateCompanionBuilder =
    InventoryCountsCompanion Function({
      Value<String> id,
      Value<String?> storeId,
      Value<String> status,
      Value<String> scope,
      Value<String?> categoryId,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime?> postedAt,
      Value<String?> postedBy,
      Value<int> rowid,
    });

final class $$InventoryCountsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InventoryCountsTable, InventoryCount> {
  $$InventoryCountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $InventoryCountItemsTable,
    List<InventoryCountItem>
  >
  _inventoryCountItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.inventoryCountItems,
        aliasName: $_aliasNameGenerator(
          db.inventoryCounts.id,
          db.inventoryCountItems.countId,
        ),
      );

  $$InventoryCountItemsTableProcessedTableManager get inventoryCountItemsRefs {
    final manager = $$InventoryCountItemsTableTableManager(
      $_db,
      $_db.inventoryCountItems,
    ).filter((f) => f.countId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoryCountItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InventoryCountsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryCountsTable> {
  $$InventoryCountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postedBy => $composableBuilder(
    column: $table.postedBy,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> inventoryCountItemsRefs(
    Expression<bool> Function($$InventoryCountItemsTableFilterComposer f) f,
  ) {
    final $$InventoryCountItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryCountItems,
      getReferencedColumn: (t) => t.countId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryCountItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryCountItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryCountsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryCountsTable> {
  $$InventoryCountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postedBy => $composableBuilder(
    column: $table.postedBy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryCountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryCountsTable> {
  $$InventoryCountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<String> get postedBy =>
      $composableBuilder(column: $table.postedBy, builder: (column) => column);

  Expression<T> inventoryCountItemsRefs<T extends Object>(
    Expression<T> Function($$InventoryCountItemsTableAnnotationComposer a) f,
  ) {
    final $$InventoryCountItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inventoryCountItems,
          getReferencedColumn: (t) => t.countId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryCountItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.inventoryCountItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$InventoryCountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryCountsTable,
          InventoryCount,
          $$InventoryCountsTableFilterComposer,
          $$InventoryCountsTableOrderingComposer,
          $$InventoryCountsTableAnnotationComposer,
          $$InventoryCountsTableCreateCompanionBuilder,
          $$InventoryCountsTableUpdateCompanionBuilder,
          (InventoryCount, $$InventoryCountsTableReferences),
          InventoryCount,
          PrefetchHooks Function({bool inventoryCountItemsRefs})
        > {
  $$InventoryCountsTableTableManager(
    _$AppDatabase db,
    $InventoryCountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryCountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryCountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryCountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> postedAt = const Value.absent(),
                Value<String?> postedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryCountsCompanion(
                id: id,
                storeId: storeId,
                status: status,
                scope: scope,
                categoryId: categoryId,
                note: note,
                createdAt: createdAt,
                postedAt: postedAt,
                postedBy: postedBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> storeId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> postedAt = const Value.absent(),
                Value<String?> postedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryCountsCompanion.insert(
                id: id,
                storeId: storeId,
                status: status,
                scope: scope,
                categoryId: categoryId,
                note: note,
                createdAt: createdAt,
                postedAt: postedAt,
                postedBy: postedBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryCountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryCountItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (inventoryCountItemsRefs) db.inventoryCountItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (inventoryCountItemsRefs)
                    await $_getPrefetchedData<
                      InventoryCount,
                      $InventoryCountsTable,
                      InventoryCountItem
                    >(
                      currentTable: table,
                      referencedTable: $$InventoryCountsTableReferences
                          ._inventoryCountItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InventoryCountsTableReferences(
                            db,
                            table,
                            p0,
                          ).inventoryCountItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.countId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InventoryCountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryCountsTable,
      InventoryCount,
      $$InventoryCountsTableFilterComposer,
      $$InventoryCountsTableOrderingComposer,
      $$InventoryCountsTableAnnotationComposer,
      $$InventoryCountsTableCreateCompanionBuilder,
      $$InventoryCountsTableUpdateCompanionBuilder,
      (InventoryCount, $$InventoryCountsTableReferences),
      InventoryCount,
      PrefetchHooks Function({bool inventoryCountItemsRefs})
    >;
typedef $$InventoryCountItemsTableCreateCompanionBuilder =
    InventoryCountItemsCompanion Function({
      required String id,
      required String countId,
      required String productId,
      Value<int?> expectedMilli,
      required int countedMilli,
      Value<int> rowid,
    });
typedef $$InventoryCountItemsTableUpdateCompanionBuilder =
    InventoryCountItemsCompanion Function({
      Value<String> id,
      Value<String> countId,
      Value<String> productId,
      Value<int?> expectedMilli,
      Value<int> countedMilli,
      Value<int> rowid,
    });

final class $$InventoryCountItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InventoryCountItemsTable,
          InventoryCountItem
        > {
  $$InventoryCountItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InventoryCountsTable _countIdTable(_$AppDatabase db) =>
      db.inventoryCounts.createAlias(
        $_aliasNameGenerator(
          db.inventoryCountItems.countId,
          db.inventoryCounts.id,
        ),
      );

  $$InventoryCountsTableProcessedTableManager get countId {
    final $_column = $_itemColumn<String>('count_id')!;

    final manager = $$InventoryCountsTableTableManager(
      $_db,
      $_db.inventoryCounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_countIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InventoryCountItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryCountItemsTable> {
  $$InventoryCountItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedMilli => $composableBuilder(
    column: $table.expectedMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countedMilli => $composableBuilder(
    column: $table.countedMilli,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoryCountsTableFilterComposer get countId {
    final $$InventoryCountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.countId,
      referencedTable: $db.inventoryCounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryCountsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryCounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryCountItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryCountItemsTable> {
  $$InventoryCountItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedMilli => $composableBuilder(
    column: $table.expectedMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countedMilli => $composableBuilder(
    column: $table.countedMilli,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoryCountsTableOrderingComposer get countId {
    final $$InventoryCountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.countId,
      referencedTable: $db.inventoryCounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryCountsTableOrderingComposer(
            $db: $db,
            $table: $db.inventoryCounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryCountItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryCountItemsTable> {
  $$InventoryCountItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get expectedMilli => $composableBuilder(
    column: $table.expectedMilli,
    builder: (column) => column,
  );

  GeneratedColumn<int> get countedMilli => $composableBuilder(
    column: $table.countedMilli,
    builder: (column) => column,
  );

  $$InventoryCountsTableAnnotationComposer get countId {
    final $$InventoryCountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.countId,
      referencedTable: $db.inventoryCounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryCountsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryCounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryCountItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryCountItemsTable,
          InventoryCountItem,
          $$InventoryCountItemsTableFilterComposer,
          $$InventoryCountItemsTableOrderingComposer,
          $$InventoryCountItemsTableAnnotationComposer,
          $$InventoryCountItemsTableCreateCompanionBuilder,
          $$InventoryCountItemsTableUpdateCompanionBuilder,
          (InventoryCountItem, $$InventoryCountItemsTableReferences),
          InventoryCountItem,
          PrefetchHooks Function({bool countId})
        > {
  $$InventoryCountItemsTableTableManager(
    _$AppDatabase db,
    $InventoryCountItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryCountItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryCountItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryCountItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> countId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int?> expectedMilli = const Value.absent(),
                Value<int> countedMilli = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryCountItemsCompanion(
                id: id,
                countId: countId,
                productId: productId,
                expectedMilli: expectedMilli,
                countedMilli: countedMilli,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String countId,
                required String productId,
                Value<int?> expectedMilli = const Value.absent(),
                required int countedMilli,
                Value<int> rowid = const Value.absent(),
              }) => InventoryCountItemsCompanion.insert(
                id: id,
                countId: countId,
                productId: productId,
                expectedMilli: expectedMilli,
                countedMilli: countedMilli,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryCountItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({countId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (countId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.countId,
                                referencedTable:
                                    $$InventoryCountItemsTableReferences
                                        ._countIdTable(db),
                                referencedColumn:
                                    $$InventoryCountItemsTableReferences
                                        ._countIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InventoryCountItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryCountItemsTable,
      InventoryCountItem,
      $$InventoryCountItemsTableFilterComposer,
      $$InventoryCountItemsTableOrderingComposer,
      $$InventoryCountItemsTableAnnotationComposer,
      $$InventoryCountItemsTableCreateCompanionBuilder,
      $$InventoryCountItemsTableUpdateCompanionBuilder,
      (InventoryCountItem, $$InventoryCountItemsTableReferences),
      InventoryCountItem,
      PrefetchHooks Function({bool countId})
    >;
typedef $$StockMovementsTableCreateCompanionBuilder =
    StockMovementsCompanion Function({
      required String id,
      required String productId,
      Value<String?> storeId,
      required int qtyMilli,
      required String type,
      required String refType,
      required String refId,
      Value<String?> outboxEventId,
      required DateTime at,
      Value<int> rowid,
    });
typedef $$StockMovementsTableUpdateCompanionBuilder =
    StockMovementsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String?> storeId,
      Value<int> qtyMilli,
      Value<String> type,
      Value<String> refType,
      Value<String> refId,
      Value<String?> outboxEventId,
      Value<DateTime> at,
      Value<int> rowid,
    });

class $$StockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refType => $composableBuilder(
    column: $table.refType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outboxEventId => $composableBuilder(
    column: $table.outboxEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refType => $composableBuilder(
    column: $table.refType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outboxEventId => $composableBuilder(
    column: $table.outboxEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<int> get qtyMilli =>
      $composableBuilder(column: $table.qtyMilli, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get refType =>
      $composableBuilder(column: $table.refType, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get outboxEventId => $composableBuilder(
    column: $table.outboxEventId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$StockMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockMovementsTable,
          StockMovement,
          $$StockMovementsTableFilterComposer,
          $$StockMovementsTableOrderingComposer,
          $$StockMovementsTableAnnotationComposer,
          $$StockMovementsTableCreateCompanionBuilder,
          $$StockMovementsTableUpdateCompanionBuilder,
          (
            StockMovement,
            BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovement>,
          ),
          StockMovement,
          PrefetchHooks Function()
        > {
  $$StockMovementsTableTableManager(
    _$AppDatabase db,
    $StockMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<int> qtyMilli = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> refType = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<String?> outboxEventId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion(
                id: id,
                productId: productId,
                storeId: storeId,
                qtyMilli: qtyMilli,
                type: type,
                refType: refType,
                refId: refId,
                outboxEventId: outboxEventId,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                Value<String?> storeId = const Value.absent(),
                required int qtyMilli,
                required String type,
                required String refType,
                required String refId,
                Value<String?> outboxEventId = const Value.absent(),
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion.insert(
                id: id,
                productId: productId,
                storeId: storeId,
                qtyMilli: qtyMilli,
                type: type,
                refType: refType,
                refId: refId,
                outboxEventId: outboxEventId,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockMovementsTable,
      StockMovement,
      $$StockMovementsTableFilterComposer,
      $$StockMovementsTableOrderingComposer,
      $$StockMovementsTableAnnotationComposer,
      $$StockMovementsTableCreateCompanionBuilder,
      $$StockMovementsTableUpdateCompanionBuilder,
      (
        StockMovement,
        BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovement>,
      ),
      StockMovement,
      PrefetchHooks Function()
    >;
typedef $$OutboxEventsTableCreateCompanionBuilder =
    OutboxEventsCompanion Function({
      required String id,
      required String type,
      required String payload,
      required DateTime createdAt,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime?> sentAt,
      Value<int> rowid,
    });
typedef $$OutboxEventsTableUpdateCompanionBuilder =
    OutboxEventsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime?> sentAt,
      Value<int> rowid,
    });

class $$OutboxEventsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$OutboxEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEventsTable,
          OutboxEvent,
          $$OutboxEventsTableFilterComposer,
          $$OutboxEventsTableOrderingComposer,
          $$OutboxEventsTableAnnotationComposer,
          $$OutboxEventsTableCreateCompanionBuilder,
          $$OutboxEventsTableUpdateCompanionBuilder,
          (
            OutboxEvent,
            BaseReferences<_$AppDatabase, $OutboxEventsTable, OutboxEvent>,
          ),
          OutboxEvent,
          PrefetchHooks Function()
        > {
  $$OutboxEventsTableTableManager(_$AppDatabase db, $OutboxEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEventsCompanion(
                id: id,
                type: type,
                payload: payload,
                createdAt: createdAt,
                status: status,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String payload,
                required DateTime createdAt,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEventsCompanion.insert(
                id: id,
                type: type,
                payload: payload,
                createdAt: createdAt,
                status: status,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEventsTable,
      OutboxEvent,
      $$OutboxEventsTableFilterComposer,
      $$OutboxEventsTableOrderingComposer,
      $$OutboxEventsTableAnnotationComposer,
      $$OutboxEventsTableCreateCompanionBuilder,
      $$OutboxEventsTableUpdateCompanionBuilder,
      (
        OutboxEvent,
        BaseReferences<_$AppDatabase, $OutboxEventsTable, OutboxEvent>,
      ),
      OutboxEvent,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      Value<int> id,
      Value<String> pullCursor,
      Value<DateTime?> lastPushAt,
      Value<DateTime?> lastPullAt,
      Value<String?> subscriptionJson,
      Value<DateTime?> offlineGraceUntil,
      Value<int> serverTimeOffsetMs,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<int> id,
      Value<String> pullCursor,
      Value<DateTime?> lastPushAt,
      Value<DateTime?> lastPullAt,
      Value<String?> subscriptionJson,
      Value<DateTime?> offlineGraceUntil,
      Value<int> serverTimeOffsetMs,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subscriptionJson => $composableBuilder(
    column: $table.subscriptionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get offlineGraceUntil => $composableBuilder(
    column: $table.offlineGraceUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverTimeOffsetMs => $composableBuilder(
    column: $table.serverTimeOffsetMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subscriptionJson => $composableBuilder(
    column: $table.subscriptionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get offlineGraceUntil => $composableBuilder(
    column: $table.offlineGraceUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverTimeOffsetMs => $composableBuilder(
    column: $table.serverTimeOffsetMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subscriptionJson => $composableBuilder(
    column: $table.subscriptionJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get offlineGraceUntil => $composableBuilder(
    column: $table.offlineGraceUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverTimeOffsetMs => $composableBuilder(
    column: $table.serverTimeOffsetMs,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pullCursor = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<String?> subscriptionJson = const Value.absent(),
                Value<DateTime?> offlineGraceUntil = const Value.absent(),
                Value<int> serverTimeOffsetMs = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                pullCursor: pullCursor,
                lastPushAt: lastPushAt,
                lastPullAt: lastPullAt,
                subscriptionJson: subscriptionJson,
                offlineGraceUntil: offlineGraceUntil,
                serverTimeOffsetMs: serverTimeOffsetMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pullCursor = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<String?> subscriptionJson = const Value.absent(),
                Value<DateTime?> offlineGraceUntil = const Value.absent(),
                Value<int> serverTimeOffsetMs = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                pullCursor: pullCursor,
                lastPushAt: lastPushAt,
                lastPullAt: lastPullAt,
                subscriptionJson: subscriptionJson,
                offlineGraceUntil: offlineGraceUntil,
                serverTimeOffsetMs: serverTimeOffsetMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;
typedef $$CartDraftsTableCreateCompanionBuilder =
    CartDraftsCompanion Function({
      required String id,
      required int slot,
      Value<String?> customerId,
      Value<String> linesJson,
      Value<String?> discountJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CartDraftsTableUpdateCompanionBuilder =
    CartDraftsCompanion Function({
      Value<String> id,
      Value<int> slot,
      Value<String?> customerId,
      Value<String> linesJson,
      Value<String?> discountJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CartDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $CartDraftsTable> {
  $$CartDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountJson => $composableBuilder(
    column: $table.discountJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CartDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $CartDraftsTable> {
  $$CartDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountJson => $composableBuilder(
    column: $table.discountJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CartDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CartDraftsTable> {
  $$CartDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linesJson =>
      $composableBuilder(column: $table.linesJson, builder: (column) => column);

  GeneratedColumn<String> get discountJson => $composableBuilder(
    column: $table.discountJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CartDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CartDraftsTable,
          CartDraft,
          $$CartDraftsTableFilterComposer,
          $$CartDraftsTableOrderingComposer,
          $$CartDraftsTableAnnotationComposer,
          $$CartDraftsTableCreateCompanionBuilder,
          $$CartDraftsTableUpdateCompanionBuilder,
          (
            CartDraft,
            BaseReferences<_$AppDatabase, $CartDraftsTable, CartDraft>,
          ),
          CartDraft,
          PrefetchHooks Function()
        > {
  $$CartDraftsTableTableManager(_$AppDatabase db, $CartDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CartDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CartDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CartDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> slot = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> linesJson = const Value.absent(),
                Value<String?> discountJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CartDraftsCompanion(
                id: id,
                slot: slot,
                customerId: customerId,
                linesJson: linesJson,
                discountJson: discountJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int slot,
                Value<String?> customerId = const Value.absent(),
                Value<String> linesJson = const Value.absent(),
                Value<String?> discountJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CartDraftsCompanion.insert(
                id: id,
                slot: slot,
                customerId: customerId,
                linesJson: linesJson,
                discountJson: discountJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CartDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CartDraftsTable,
      CartDraft,
      $$CartDraftsTableFilterComposer,
      $$CartDraftsTableOrderingComposer,
      $$CartDraftsTableAnnotationComposer,
      $$CartDraftsTableCreateCompanionBuilder,
      $$CartDraftsTableUpdateCompanionBuilder,
      (CartDraft, BaseReferences<_$AppDatabase, $CartDraftsTable, CartDraft>),
      CartDraft,
      PrefetchHooks Function()
    >;
typedef $$DocCountersTableCreateCompanionBuilder =
    DocCountersCompanion Function({
      required String name,
      required int value,
      Value<int> rowid,
    });
typedef $$DocCountersTableUpdateCompanionBuilder =
    DocCountersCompanion Function({
      Value<String> name,
      Value<int> value,
      Value<int> rowid,
    });

class $$DocCountersTableFilterComposer
    extends Composer<_$AppDatabase, $DocCountersTable> {
  $$DocCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $DocCountersTable> {
  $$DocCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocCountersTable> {
  $$DocCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$DocCountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocCountersTable,
          DocCounter,
          $$DocCountersTableFilterComposer,
          $$DocCountersTableOrderingComposer,
          $$DocCountersTableAnnotationComposer,
          $$DocCountersTableCreateCompanionBuilder,
          $$DocCountersTableUpdateCompanionBuilder,
          (
            DocCounter,
            BaseReferences<_$AppDatabase, $DocCountersTable, DocCounter>,
          ),
          DocCounter,
          PrefetchHooks Function()
        > {
  $$DocCountersTableTableManager(_$AppDatabase db, $DocCountersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  DocCountersCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required int value,
                Value<int> rowid = const Value.absent(),
              }) => DocCountersCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocCountersTable,
      DocCounter,
      $$DocCountersTableFilterComposer,
      $$DocCountersTableOrderingComposer,
      $$DocCountersTableAnnotationComposer,
      $$DocCountersTableCreateCompanionBuilder,
      $$DocCountersTableUpdateCompanionBuilder,
      (
        DocCounter,
        BaseReferences<_$AppDatabase, $DocCountersTable, DocCounter>,
      ),
      DocCounter,
      PrefetchHooks Function()
    >;
typedef $$ProductImagesTableCreateCompanionBuilder =
    ProductImagesCompanion Function({
      required String id,
      required String productId,
      required String state,
      Value<String?> byUserId,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProductImagesTableUpdateCompanionBuilder =
    ProductImagesCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> state,
      Value<String?> byUserId,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ProductImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductImagesTable> {
  $$ProductImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get byUserId => $composableBuilder(
    column: $table.byUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductImagesTable> {
  $$ProductImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get byUserId => $composableBuilder(
    column: $table.byUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductImagesTable> {
  $$ProductImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get byUserId =>
      $composableBuilder(column: $table.byUserId, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProductImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductImagesTable,
          ProductImage,
          $$ProductImagesTableFilterComposer,
          $$ProductImagesTableOrderingComposer,
          $$ProductImagesTableAnnotationComposer,
          $$ProductImagesTableCreateCompanionBuilder,
          $$ProductImagesTableUpdateCompanionBuilder,
          (
            ProductImage,
            BaseReferences<_$AppDatabase, $ProductImagesTable, ProductImage>,
          ),
          ProductImage,
          PrefetchHooks Function()
        > {
  $$ProductImagesTableTableManager(_$AppDatabase db, $ProductImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> byUserId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductImagesCompanion(
                id: id,
                productId: productId,
                state: state,
                byUserId: byUserId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String state,
                Value<String?> byUserId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductImagesCompanion.insert(
                id: id,
                productId: productId,
                state: state,
                byUserId: byUserId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductImagesTable,
      ProductImage,
      $$ProductImagesTableFilterComposer,
      $$ProductImagesTableOrderingComposer,
      $$ProductImagesTableAnnotationComposer,
      $$ProductImagesTableCreateCompanionBuilder,
      $$ProductImagesTableUpdateCompanionBuilder,
      (
        ProductImage,
        BaseReferences<_$AppDatabase, $ProductImagesTable, ProductImage>,
      ),
      ProductImage,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db, _db.stores);
  $$StaffUsersTableTableManager get staffUsers =>
      $$StaffUsersTableTableManager(_db, _db.staffUsers);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductBarcodesTableTableManager get productBarcodes =>
      $$ProductBarcodesTableTableManager(_db, _db.productBarcodes);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db, _db.suppliers);
  $$ProductStockTableTableManager get productStock =>
      $$ProductStockTableTableManager(_db, _db.productStock);
  $$DebtEntriesTableTableManager get debtEntries =>
      $$DebtEntriesTableTableManager(_db, _db.debtEntries);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db, _db.saleItems);
  $$SalePaymentsTableTableManager get salePayments =>
      $$SalePaymentsTableTableManager(_db, _db.salePayments);
  $$RefundsTableTableManager get refunds =>
      $$RefundsTableTableManager(_db, _db.refunds);
  $$RefundItemsTableTableManager get refundItems =>
      $$RefundItemsTableTableManager(_db, _db.refundItems);
  $$CashMovementsTableTableManager get cashMovements =>
      $$CashMovementsTableTableManager(_db, _db.cashMovements);
  $$StockReceiptsTableTableManager get stockReceipts =>
      $$StockReceiptsTableTableManager(_db, _db.stockReceipts);
  $$StockReceiptItemsTableTableManager get stockReceiptItems =>
      $$StockReceiptItemsTableTableManager(_db, _db.stockReceiptItems);
  $$InventoryCountsTableTableManager get inventoryCounts =>
      $$InventoryCountsTableTableManager(_db, _db.inventoryCounts);
  $$InventoryCountItemsTableTableManager get inventoryCountItems =>
      $$InventoryCountItemsTableTableManager(_db, _db.inventoryCountItems);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$OutboxEventsTableTableManager get outboxEvents =>
      $$OutboxEventsTableTableManager(_db, _db.outboxEvents);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$CartDraftsTableTableManager get cartDrafts =>
      $$CartDraftsTableTableManager(_db, _db.cartDrafts);
  $$DocCountersTableTableManager get docCounters =>
      $$DocCountersTableTableManager(_db, _db.docCounters);
  $$ProductImagesTableTableManager get productImages =>
      $$ProductImagesTableTableManager(_db, _db.productImages);
}
