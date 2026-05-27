// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VehiclesTable extends Vehicles
    with TableInfo<$VehiclesTable, VehicleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _makeMeta = const VerificationMeta('make');
  @override
  late final GeneratedColumn<String> make = GeneratedColumn<String>(
    'make',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ufMeta = const VerificationMeta('uf');
  @override
  late final GeneratedColumn<String> uf = GeneratedColumn<String>(
    'uf',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  late final GeneratedColumnWithTypeConverter<VehicleType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('carro'),
      ).withConverter<VehicleType>($VehiclesTable.$convertertype);
  static const VerificationMeta _engineDisplacementCcMeta =
      const VerificationMeta('engineDisplacementCc');
  @override
  late final GeneratedColumn<int> engineDisplacementCc = GeneratedColumn<int>(
    'engine_displacement_cc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> tankCapacityL =
      GeneratedColumn<String>(
        'tank_capacity_l',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($VehiclesTable.$convertertankCapacityLn);
  static const VerificationMeta _horsepowerMeta = const VerificationMeta(
    'horsepower',
  );
  @override
  late final GeneratedColumn<int> horsepower = GeneratedColumn<int>(
    'horsepower',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fipeCodeMeta = const VerificationMeta(
    'fipeCode',
  );
  @override
  late final GeneratedColumn<String> fipeCode = GeneratedColumn<String>(
    'fipe_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> fipeValue =
      GeneratedColumn<String>(
        'fipe_value',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($VehiclesTable.$converterfipeValuen);
  static const VerificationMeta _fipeReferenceMonthMeta =
      const VerificationMeta('fipeReferenceMonth');
  @override
  late final GeneratedColumn<String> fipeReferenceMonth =
      GeneratedColumn<String>(
        'fipe_reference_month',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _plateMeta = const VerificationMeta('plate');
  @override
  late final GeneratedColumn<String> plate = GeneratedColumn<String>(
    'plate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _renavamMeta = const VerificationMeta(
    'renavam',
  );
  @override
  late final GeneratedColumn<String> renavam = GeneratedColumn<String>(
    'renavam',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chassiMeta = const VerificationMeta('chassi');
  @override
  late final GeneratedColumn<String> chassi = GeneratedColumn<String>(
    'chassi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FuelType, String> fuelType =
      GeneratedColumn<String>(
        'fuel_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FuelType>($VehiclesTable.$converterfuelType);
  static const VerificationMeta _initialOdometerMeta = const VerificationMeta(
    'initialOdometer',
  );
  @override
  late final GeneratedColumn<int> initialOdometer = GeneratedColumn<int>(
    'initial_odometer',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncStatus>($VehiclesTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    nickname,
    make,
    model,
    year,
    uf,
    color,
    type,
    engineDisplacementCc,
    tankCapacityL,
    horsepower,
    fipeCode,
    fipeValue,
    fipeReferenceMonth,
    plate,
    renavam,
    chassi,
    fuelType,
    initialOdometer,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<VehicleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('make')) {
      context.handle(
        _makeMeta,
        make.isAcceptableOrUnknown(data['make']!, _makeMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('uf')) {
      context.handle(_ufMeta, uf.isAcceptableOrUnknown(data['uf']!, _ufMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('engine_displacement_cc')) {
      context.handle(
        _engineDisplacementCcMeta,
        engineDisplacementCc.isAcceptableOrUnknown(
          data['engine_displacement_cc']!,
          _engineDisplacementCcMeta,
        ),
      );
    }
    if (data.containsKey('horsepower')) {
      context.handle(
        _horsepowerMeta,
        horsepower.isAcceptableOrUnknown(data['horsepower']!, _horsepowerMeta),
      );
    }
    if (data.containsKey('fipe_code')) {
      context.handle(
        _fipeCodeMeta,
        fipeCode.isAcceptableOrUnknown(data['fipe_code']!, _fipeCodeMeta),
      );
    }
    if (data.containsKey('fipe_reference_month')) {
      context.handle(
        _fipeReferenceMonthMeta,
        fipeReferenceMonth.isAcceptableOrUnknown(
          data['fipe_reference_month']!,
          _fipeReferenceMonthMeta,
        ),
      );
    }
    if (data.containsKey('plate')) {
      context.handle(
        _plateMeta,
        plate.isAcceptableOrUnknown(data['plate']!, _plateMeta),
      );
    }
    if (data.containsKey('renavam')) {
      context.handle(
        _renavamMeta,
        renavam.isAcceptableOrUnknown(data['renavam']!, _renavamMeta),
      );
    }
    if (data.containsKey('chassi')) {
      context.handle(
        _chassiMeta,
        chassi.isAcceptableOrUnknown(data['chassi']!, _chassiMeta),
      );
    }
    if (data.containsKey('initial_odometer')) {
      context.handle(
        _initialOdometerMeta,
        initialOdometer.isAcceptableOrUnknown(
          data['initial_odometer']!,
          _initialOdometerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialOdometerMeta);
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
  VehicleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VehicleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      make: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}make'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      uf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uf'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      type: $VehiclesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      engineDisplacementCc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}engine_displacement_cc'],
      ),
      tankCapacityL: $VehiclesTable.$convertertankCapacityLn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tank_capacity_l'],
        ),
      ),
      horsepower: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}horsepower'],
      ),
      fipeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fipe_code'],
      ),
      fipeValue: $VehiclesTable.$converterfipeValuen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fipe_value'],
        ),
      ),
      fipeReferenceMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fipe_reference_month'],
      ),
      plate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plate'],
      ),
      renavam: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}renavam'],
      ),
      chassi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chassi'],
      ),
      fuelType: $VehiclesTable.$converterfuelType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fuel_type'],
        )!,
      ),
      initialOdometer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_odometer'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $VehiclesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }

  static TypeConverter<VehicleType, String> $convertertype =
      const VehicleTypeConverter();
  static TypeConverter<Decimal, String> $convertertankCapacityL =
      const DecimalConverter();
  static TypeConverter<Decimal?, String?> $convertertankCapacityLn =
      NullAwareTypeConverter.wrap($convertertankCapacityL);
  static TypeConverter<Decimal, String> $converterfipeValue =
      const DecimalConverter();
  static TypeConverter<Decimal?, String?> $converterfipeValuen =
      NullAwareTypeConverter.wrap($converterfipeValue);
  static TypeConverter<FuelType, String> $converterfuelType =
      const FuelTypeConverter();
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class VehicleRow extends DataClass implements Insertable<VehicleRow> {
  /// PK: UUID gerado no client.
  final String id;
  final String userId;
  final String nickname;
  final String? make;
  final String? model;
  final int? year;
  final String? uf;
  final String? color;
  final VehicleType type;
  final int? engineDisplacementCc;
  final Decimal? tankCapacityL;
  final int? horsepower;
  final String? fipeCode;
  final Decimal? fipeValue;
  final String? fipeReferenceMonth;
  final String? plate;
  final String? renavam;
  final String? chassi;
  final FuelType fuelType;
  final int initialOdometer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  const VehicleRow({
    required this.id,
    required this.userId,
    required this.nickname,
    this.make,
    this.model,
    this.year,
    this.uf,
    this.color,
    required this.type,
    this.engineDisplacementCc,
    this.tankCapacityL,
    this.horsepower,
    this.fipeCode,
    this.fipeValue,
    this.fipeReferenceMonth,
    this.plate,
    this.renavam,
    this.chassi,
    required this.fuelType,
    required this.initialOdometer,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['nickname'] = Variable<String>(nickname);
    if (!nullToAbsent || make != null) {
      map['make'] = Variable<String>(make);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || uf != null) {
      map['uf'] = Variable<String>(uf);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    {
      map['type'] = Variable<String>($VehiclesTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || engineDisplacementCc != null) {
      map['engine_displacement_cc'] = Variable<int>(engineDisplacementCc);
    }
    if (!nullToAbsent || tankCapacityL != null) {
      map['tank_capacity_l'] = Variable<String>(
        $VehiclesTable.$convertertankCapacityLn.toSql(tankCapacityL),
      );
    }
    if (!nullToAbsent || horsepower != null) {
      map['horsepower'] = Variable<int>(horsepower);
    }
    if (!nullToAbsent || fipeCode != null) {
      map['fipe_code'] = Variable<String>(fipeCode);
    }
    if (!nullToAbsent || fipeValue != null) {
      map['fipe_value'] = Variable<String>(
        $VehiclesTable.$converterfipeValuen.toSql(fipeValue),
      );
    }
    if (!nullToAbsent || fipeReferenceMonth != null) {
      map['fipe_reference_month'] = Variable<String>(fipeReferenceMonth);
    }
    if (!nullToAbsent || plate != null) {
      map['plate'] = Variable<String>(plate);
    }
    if (!nullToAbsent || renavam != null) {
      map['renavam'] = Variable<String>(renavam);
    }
    if (!nullToAbsent || chassi != null) {
      map['chassi'] = Variable<String>(chassi);
    }
    {
      map['fuel_type'] = Variable<String>(
        $VehiclesTable.$converterfuelType.toSql(fuelType),
      );
    }
    map['initial_odometer'] = Variable<int>(initialOdometer);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    {
      map['sync_status'] = Variable<String>(
        $VehiclesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      userId: Value(userId),
      nickname: Value(nickname),
      make: make == null && nullToAbsent ? const Value.absent() : Value(make),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      uf: uf == null && nullToAbsent ? const Value.absent() : Value(uf),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      type: Value(type),
      engineDisplacementCc: engineDisplacementCc == null && nullToAbsent
          ? const Value.absent()
          : Value(engineDisplacementCc),
      tankCapacityL: tankCapacityL == null && nullToAbsent
          ? const Value.absent()
          : Value(tankCapacityL),
      horsepower: horsepower == null && nullToAbsent
          ? const Value.absent()
          : Value(horsepower),
      fipeCode: fipeCode == null && nullToAbsent
          ? const Value.absent()
          : Value(fipeCode),
      fipeValue: fipeValue == null && nullToAbsent
          ? const Value.absent()
          : Value(fipeValue),
      fipeReferenceMonth: fipeReferenceMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(fipeReferenceMonth),
      plate: plate == null && nullToAbsent
          ? const Value.absent()
          : Value(plate),
      renavam: renavam == null && nullToAbsent
          ? const Value.absent()
          : Value(renavam),
      chassi: chassi == null && nullToAbsent
          ? const Value.absent()
          : Value(chassi),
      fuelType: Value(fuelType),
      initialOdometer: Value(initialOdometer),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory VehicleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VehicleRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      nickname: serializer.fromJson<String>(json['nickname']),
      make: serializer.fromJson<String?>(json['make']),
      model: serializer.fromJson<String?>(json['model']),
      year: serializer.fromJson<int?>(json['year']),
      uf: serializer.fromJson<String?>(json['uf']),
      color: serializer.fromJson<String?>(json['color']),
      type: serializer.fromJson<VehicleType>(json['type']),
      engineDisplacementCc: serializer.fromJson<int?>(
        json['engineDisplacementCc'],
      ),
      tankCapacityL: serializer.fromJson<Decimal?>(json['tankCapacityL']),
      horsepower: serializer.fromJson<int?>(json['horsepower']),
      fipeCode: serializer.fromJson<String?>(json['fipeCode']),
      fipeValue: serializer.fromJson<Decimal?>(json['fipeValue']),
      fipeReferenceMonth: serializer.fromJson<String?>(
        json['fipeReferenceMonth'],
      ),
      plate: serializer.fromJson<String?>(json['plate']),
      renavam: serializer.fromJson<String?>(json['renavam']),
      chassi: serializer.fromJson<String?>(json['chassi']),
      fuelType: serializer.fromJson<FuelType>(json['fuelType']),
      initialOdometer: serializer.fromJson<int>(json['initialOdometer']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'nickname': serializer.toJson<String>(nickname),
      'make': serializer.toJson<String?>(make),
      'model': serializer.toJson<String?>(model),
      'year': serializer.toJson<int?>(year),
      'uf': serializer.toJson<String?>(uf),
      'color': serializer.toJson<String?>(color),
      'type': serializer.toJson<VehicleType>(type),
      'engineDisplacementCc': serializer.toJson<int?>(engineDisplacementCc),
      'tankCapacityL': serializer.toJson<Decimal?>(tankCapacityL),
      'horsepower': serializer.toJson<int?>(horsepower),
      'fipeCode': serializer.toJson<String?>(fipeCode),
      'fipeValue': serializer.toJson<Decimal?>(fipeValue),
      'fipeReferenceMonth': serializer.toJson<String?>(fipeReferenceMonth),
      'plate': serializer.toJson<String?>(plate),
      'renavam': serializer.toJson<String?>(renavam),
      'chassi': serializer.toJson<String?>(chassi),
      'fuelType': serializer.toJson<FuelType>(fuelType),
      'initialOdometer': serializer.toJson<int>(initialOdometer),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  VehicleRow copyWith({
    String? id,
    String? userId,
    String? nickname,
    Value<String?> make = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> uf = const Value.absent(),
    Value<String?> color = const Value.absent(),
    VehicleType? type,
    Value<int?> engineDisplacementCc = const Value.absent(),
    Value<Decimal?> tankCapacityL = const Value.absent(),
    Value<int?> horsepower = const Value.absent(),
    Value<String?> fipeCode = const Value.absent(),
    Value<Decimal?> fipeValue = const Value.absent(),
    Value<String?> fipeReferenceMonth = const Value.absent(),
    Value<String?> plate = const Value.absent(),
    Value<String?> renavam = const Value.absent(),
    Value<String?> chassi = const Value.absent(),
    FuelType? fuelType,
    int? initialOdometer,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
  }) => VehicleRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    nickname: nickname ?? this.nickname,
    make: make.present ? make.value : this.make,
    model: model.present ? model.value : this.model,
    year: year.present ? year.value : this.year,
    uf: uf.present ? uf.value : this.uf,
    color: color.present ? color.value : this.color,
    type: type ?? this.type,
    engineDisplacementCc: engineDisplacementCc.present
        ? engineDisplacementCc.value
        : this.engineDisplacementCc,
    tankCapacityL: tankCapacityL.present
        ? tankCapacityL.value
        : this.tankCapacityL,
    horsepower: horsepower.present ? horsepower.value : this.horsepower,
    fipeCode: fipeCode.present ? fipeCode.value : this.fipeCode,
    fipeValue: fipeValue.present ? fipeValue.value : this.fipeValue,
    fipeReferenceMonth: fipeReferenceMonth.present
        ? fipeReferenceMonth.value
        : this.fipeReferenceMonth,
    plate: plate.present ? plate.value : this.plate,
    renavam: renavam.present ? renavam.value : this.renavam,
    chassi: chassi.present ? chassi.value : this.chassi,
    fuelType: fuelType ?? this.fuelType,
    initialOdometer: initialOdometer ?? this.initialOdometer,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  VehicleRow copyWithCompanion(VehiclesCompanion data) {
    return VehicleRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      make: data.make.present ? data.make.value : this.make,
      model: data.model.present ? data.model.value : this.model,
      year: data.year.present ? data.year.value : this.year,
      uf: data.uf.present ? data.uf.value : this.uf,
      color: data.color.present ? data.color.value : this.color,
      type: data.type.present ? data.type.value : this.type,
      engineDisplacementCc: data.engineDisplacementCc.present
          ? data.engineDisplacementCc.value
          : this.engineDisplacementCc,
      tankCapacityL: data.tankCapacityL.present
          ? data.tankCapacityL.value
          : this.tankCapacityL,
      horsepower: data.horsepower.present
          ? data.horsepower.value
          : this.horsepower,
      fipeCode: data.fipeCode.present ? data.fipeCode.value : this.fipeCode,
      fipeValue: data.fipeValue.present ? data.fipeValue.value : this.fipeValue,
      fipeReferenceMonth: data.fipeReferenceMonth.present
          ? data.fipeReferenceMonth.value
          : this.fipeReferenceMonth,
      plate: data.plate.present ? data.plate.value : this.plate,
      renavam: data.renavam.present ? data.renavam.value : this.renavam,
      chassi: data.chassi.present ? data.chassi.value : this.chassi,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      initialOdometer: data.initialOdometer.present
          ? data.initialOdometer.value
          : this.initialOdometer,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VehicleRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('nickname: $nickname, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('uf: $uf, ')
          ..write('color: $color, ')
          ..write('type: $type, ')
          ..write('engineDisplacementCc: $engineDisplacementCc, ')
          ..write('tankCapacityL: $tankCapacityL, ')
          ..write('horsepower: $horsepower, ')
          ..write('fipeCode: $fipeCode, ')
          ..write('fipeValue: $fipeValue, ')
          ..write('fipeReferenceMonth: $fipeReferenceMonth, ')
          ..write('plate: $plate, ')
          ..write('renavam: $renavam, ')
          ..write('chassi: $chassi, ')
          ..write('fuelType: $fuelType, ')
          ..write('initialOdometer: $initialOdometer, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    nickname,
    make,
    model,
    year,
    uf,
    color,
    type,
    engineDisplacementCc,
    tankCapacityL,
    horsepower,
    fipeCode,
    fipeValue,
    fipeReferenceMonth,
    plate,
    renavam,
    chassi,
    fuelType,
    initialOdometer,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VehicleRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.nickname == this.nickname &&
          other.make == this.make &&
          other.model == this.model &&
          other.year == this.year &&
          other.uf == this.uf &&
          other.color == this.color &&
          other.type == this.type &&
          other.engineDisplacementCc == this.engineDisplacementCc &&
          other.tankCapacityL == this.tankCapacityL &&
          other.horsepower == this.horsepower &&
          other.fipeCode == this.fipeCode &&
          other.fipeValue == this.fipeValue &&
          other.fipeReferenceMonth == this.fipeReferenceMonth &&
          other.plate == this.plate &&
          other.renavam == this.renavam &&
          other.chassi == this.chassi &&
          other.fuelType == this.fuelType &&
          other.initialOdometer == this.initialOdometer &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class VehiclesCompanion extends UpdateCompanion<VehicleRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> nickname;
  final Value<String?> make;
  final Value<String?> model;
  final Value<int?> year;
  final Value<String?> uf;
  final Value<String?> color;
  final Value<VehicleType> type;
  final Value<int?> engineDisplacementCc;
  final Value<Decimal?> tankCapacityL;
  final Value<int?> horsepower;
  final Value<String?> fipeCode;
  final Value<Decimal?> fipeValue;
  final Value<String?> fipeReferenceMonth;
  final Value<String?> plate;
  final Value<String?> renavam;
  final Value<String?> chassi;
  final Value<FuelType> fuelType;
  final Value<int> initialOdometer;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.nickname = const Value.absent(),
    this.make = const Value.absent(),
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    this.uf = const Value.absent(),
    this.color = const Value.absent(),
    this.type = const Value.absent(),
    this.engineDisplacementCc = const Value.absent(),
    this.tankCapacityL = const Value.absent(),
    this.horsepower = const Value.absent(),
    this.fipeCode = const Value.absent(),
    this.fipeValue = const Value.absent(),
    this.fipeReferenceMonth = const Value.absent(),
    this.plate = const Value.absent(),
    this.renavam = const Value.absent(),
    this.chassi = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.initialOdometer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VehiclesCompanion.insert({
    required String id,
    required String userId,
    required String nickname,
    this.make = const Value.absent(),
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    this.uf = const Value.absent(),
    this.color = const Value.absent(),
    this.type = const Value.absent(),
    this.engineDisplacementCc = const Value.absent(),
    this.tankCapacityL = const Value.absent(),
    this.horsepower = const Value.absent(),
    this.fipeCode = const Value.absent(),
    this.fipeValue = const Value.absent(),
    this.fipeReferenceMonth = const Value.absent(),
    this.plate = const Value.absent(),
    this.renavam = const Value.absent(),
    this.chassi = const Value.absent(),
    required FuelType fuelType,
    required int initialOdometer,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       nickname = Value(nickname),
       fuelType = Value(fuelType),
       initialOdometer = Value(initialOdometer),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VehicleRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? nickname,
    Expression<String>? make,
    Expression<String>? model,
    Expression<int>? year,
    Expression<String>? uf,
    Expression<String>? color,
    Expression<String>? type,
    Expression<int>? engineDisplacementCc,
    Expression<String>? tankCapacityL,
    Expression<int>? horsepower,
    Expression<String>? fipeCode,
    Expression<String>? fipeValue,
    Expression<String>? fipeReferenceMonth,
    Expression<String>? plate,
    Expression<String>? renavam,
    Expression<String>? chassi,
    Expression<String>? fuelType,
    Expression<int>? initialOdometer,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (nickname != null) 'nickname': nickname,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (uf != null) 'uf': uf,
      if (color != null) 'color': color,
      if (type != null) 'type': type,
      if (engineDisplacementCc != null)
        'engine_displacement_cc': engineDisplacementCc,
      if (tankCapacityL != null) 'tank_capacity_l': tankCapacityL,
      if (horsepower != null) 'horsepower': horsepower,
      if (fipeCode != null) 'fipe_code': fipeCode,
      if (fipeValue != null) 'fipe_value': fipeValue,
      if (fipeReferenceMonth != null)
        'fipe_reference_month': fipeReferenceMonth,
      if (plate != null) 'plate': plate,
      if (renavam != null) 'renavam': renavam,
      if (chassi != null) 'chassi': chassi,
      if (fuelType != null) 'fuel_type': fuelType,
      if (initialOdometer != null) 'initial_odometer': initialOdometer,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VehiclesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? nickname,
    Value<String?>? make,
    Value<String?>? model,
    Value<int?>? year,
    Value<String?>? uf,
    Value<String?>? color,
    Value<VehicleType>? type,
    Value<int?>? engineDisplacementCc,
    Value<Decimal?>? tankCapacityL,
    Value<int?>? horsepower,
    Value<String?>? fipeCode,
    Value<Decimal?>? fipeValue,
    Value<String?>? fipeReferenceMonth,
    Value<String?>? plate,
    Value<String?>? renavam,
    Value<String?>? chassi,
    Value<FuelType>? fuelType,
    Value<int>? initialOdometer,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      uf: uf ?? this.uf,
      color: color ?? this.color,
      type: type ?? this.type,
      engineDisplacementCc: engineDisplacementCc ?? this.engineDisplacementCc,
      tankCapacityL: tankCapacityL ?? this.tankCapacityL,
      horsepower: horsepower ?? this.horsepower,
      fipeCode: fipeCode ?? this.fipeCode,
      fipeValue: fipeValue ?? this.fipeValue,
      fipeReferenceMonth: fipeReferenceMonth ?? this.fipeReferenceMonth,
      plate: plate ?? this.plate,
      renavam: renavam ?? this.renavam,
      chassi: chassi ?? this.chassi,
      fuelType: fuelType ?? this.fuelType,
      initialOdometer: initialOdometer ?? this.initialOdometer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (make.present) {
      map['make'] = Variable<String>(make.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (uf.present) {
      map['uf'] = Variable<String>(uf.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $VehiclesTable.$convertertype.toSql(type.value),
      );
    }
    if (engineDisplacementCc.present) {
      map['engine_displacement_cc'] = Variable<int>(engineDisplacementCc.value);
    }
    if (tankCapacityL.present) {
      map['tank_capacity_l'] = Variable<String>(
        $VehiclesTable.$convertertankCapacityLn.toSql(tankCapacityL.value),
      );
    }
    if (horsepower.present) {
      map['horsepower'] = Variable<int>(horsepower.value);
    }
    if (fipeCode.present) {
      map['fipe_code'] = Variable<String>(fipeCode.value);
    }
    if (fipeValue.present) {
      map['fipe_value'] = Variable<String>(
        $VehiclesTable.$converterfipeValuen.toSql(fipeValue.value),
      );
    }
    if (fipeReferenceMonth.present) {
      map['fipe_reference_month'] = Variable<String>(fipeReferenceMonth.value);
    }
    if (plate.present) {
      map['plate'] = Variable<String>(plate.value);
    }
    if (renavam.present) {
      map['renavam'] = Variable<String>(renavam.value);
    }
    if (chassi.present) {
      map['chassi'] = Variable<String>(chassi.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(
        $VehiclesTable.$converterfuelType.toSql(fuelType.value),
      );
    }
    if (initialOdometer.present) {
      map['initial_odometer'] = Variable<int>(initialOdometer.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $VehiclesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('nickname: $nickname, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('uf: $uf, ')
          ..write('color: $color, ')
          ..write('type: $type, ')
          ..write('engineDisplacementCc: $engineDisplacementCc, ')
          ..write('tankCapacityL: $tankCapacityL, ')
          ..write('horsepower: $horsepower, ')
          ..write('fipeCode: $fipeCode, ')
          ..write('fipeValue: $fipeValue, ')
          ..write('fipeReferenceMonth: $fipeReferenceMonth, ')
          ..write('plate: $plate, ')
          ..write('renavam: $renavam, ')
          ..write('chassi: $chassi, ')
          ..write('fuelType: $fuelType, ')
          ..write('initialOdometer: $initialOdometer, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FuelEntriesTable extends FuelEntries
    with TableInfo<$FuelEntriesTable, FuelEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FuelEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _odometerMeta = const VerificationMeta(
    'odometer',
  );
  @override
  late final GeneratedColumn<int> odometer = GeneratedColumn<int>(
    'odometer',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> liters =
      GeneratedColumn<String>(
        'liters',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($FuelEntriesTable.$converterliters);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> pricePerLiter =
      GeneratedColumn<String>(
        'price_per_liter',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($FuelEntriesTable.$converterpricePerLiter);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> totalCost =
      GeneratedColumn<String>(
        'total_cost',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($FuelEntriesTable.$convertertotalCost);
  static const VerificationMeta _fullTankMeta = const VerificationMeta(
    'fullTank',
  );
  @override
  late final GeneratedColumn<bool> fullTank = GeneratedColumn<bool>(
    'full_tank',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("full_tank" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FuelType, String> fuelType =
      GeneratedColumn<String>(
        'fuel_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FuelType>($FuelEntriesTable.$converterfuelType);
  @override
  late final GeneratedColumnWithTypeConverter<FuelSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FuelSource>($FuelEntriesTable.$convertersource);
  static const VerificationMeta _receiptImageUrlMeta = const VerificationMeta(
    'receiptImageUrl',
  );
  @override
  late final GeneratedColumn<String> receiptImageUrl = GeneratedColumn<String>(
    'receipt_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stationNameMeta = const VerificationMeta(
    'stationName',
  );
  @override
  late final GeneratedColumn<String> stationName = GeneratedColumn<String>(
    'station_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stationBrandMeta = const VerificationMeta(
    'stationBrand',
  );
  @override
  late final GeneratedColumn<String> stationBrand = GeneratedColumn<String>(
    'station_brand',
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
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncStatus>($FuelEntriesTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    date,
    odometer,
    liters,
    pricePerLiter,
    totalCost,
    fullTank,
    fuelType,
    source,
    receiptImageUrl,
    stationName,
    stationBrand,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fuel_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('odometer')) {
      context.handle(
        _odometerMeta,
        odometer.isAcceptableOrUnknown(data['odometer']!, _odometerMeta),
      );
    } else if (isInserting) {
      context.missing(_odometerMeta);
    }
    if (data.containsKey('full_tank')) {
      context.handle(
        _fullTankMeta,
        fullTank.isAcceptableOrUnknown(data['full_tank']!, _fullTankMeta),
      );
    } else if (isInserting) {
      context.missing(_fullTankMeta);
    }
    if (data.containsKey('receipt_image_url')) {
      context.handle(
        _receiptImageUrlMeta,
        receiptImageUrl.isAcceptableOrUnknown(
          data['receipt_image_url']!,
          _receiptImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('station_name')) {
      context.handle(
        _stationNameMeta,
        stationName.isAcceptableOrUnknown(
          data['station_name']!,
          _stationNameMeta,
        ),
      );
    }
    if (data.containsKey('station_brand')) {
      context.handle(
        _stationBrandMeta,
        stationBrand.isAcceptableOrUnknown(
          data['station_brand']!,
          _stationBrandMeta,
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
  FuelEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      odometer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}odometer'],
      )!,
      liters: $FuelEntriesTable.$converterliters.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}liters'],
        )!,
      ),
      pricePerLiter: $FuelEntriesTable.$converterpricePerLiter.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}price_per_liter'],
        )!,
      ),
      totalCost: $FuelEntriesTable.$convertertotalCost.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}total_cost'],
        )!,
      ),
      fullTank: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}full_tank'],
      )!,
      fuelType: $FuelEntriesTable.$converterfuelType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fuel_type'],
        )!,
      ),
      source: $FuelEntriesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      receiptImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_image_url'],
      ),
      stationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_name'],
      ),
      stationBrand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_brand'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $FuelEntriesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $FuelEntriesTable createAlias(String alias) {
    return $FuelEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterliters =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterpricePerLiter =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $convertertotalCost =
      const DecimalConverter();
  static TypeConverter<FuelType, String> $converterfuelType =
      const FuelTypeConverter();
  static TypeConverter<FuelSource, String> $convertersource =
      const FuelSourceConverter();
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class FuelEntryRow extends DataClass implements Insertable<FuelEntryRow> {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometer;
  final Decimal liters;
  final Decimal pricePerLiter;
  final Decimal totalCost;
  final bool fullTank;
  final FuelType fuelType;
  final FuelSource source;
  final String? receiptImageUrl;
  final String? stationName;
  final String? stationBrand;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  const FuelEntryRow({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.fullTank,
    required this.fuelType,
    required this.source,
    this.receiptImageUrl,
    this.stationName,
    this.stationBrand,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['date'] = Variable<DateTime>(date);
    map['odometer'] = Variable<int>(odometer);
    {
      map['liters'] = Variable<String>(
        $FuelEntriesTable.$converterliters.toSql(liters),
      );
    }
    {
      map['price_per_liter'] = Variable<String>(
        $FuelEntriesTable.$converterpricePerLiter.toSql(pricePerLiter),
      );
    }
    {
      map['total_cost'] = Variable<String>(
        $FuelEntriesTable.$convertertotalCost.toSql(totalCost),
      );
    }
    map['full_tank'] = Variable<bool>(fullTank);
    {
      map['fuel_type'] = Variable<String>(
        $FuelEntriesTable.$converterfuelType.toSql(fuelType),
      );
    }
    {
      map['source'] = Variable<String>(
        $FuelEntriesTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || receiptImageUrl != null) {
      map['receipt_image_url'] = Variable<String>(receiptImageUrl);
    }
    if (!nullToAbsent || stationName != null) {
      map['station_name'] = Variable<String>(stationName);
    }
    if (!nullToAbsent || stationBrand != null) {
      map['station_brand'] = Variable<String>(stationBrand);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    {
      map['sync_status'] = Variable<String>(
        $FuelEntriesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  FuelEntriesCompanion toCompanion(bool nullToAbsent) {
    return FuelEntriesCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      date: Value(date),
      odometer: Value(odometer),
      liters: Value(liters),
      pricePerLiter: Value(pricePerLiter),
      totalCost: Value(totalCost),
      fullTank: Value(fullTank),
      fuelType: Value(fuelType),
      source: Value(source),
      receiptImageUrl: receiptImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptImageUrl),
      stationName: stationName == null && nullToAbsent
          ? const Value.absent()
          : Value(stationName),
      stationBrand: stationBrand == null && nullToAbsent
          ? const Value.absent()
          : Value(stationBrand),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory FuelEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelEntryRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      date: serializer.fromJson<DateTime>(json['date']),
      odometer: serializer.fromJson<int>(json['odometer']),
      liters: serializer.fromJson<Decimal>(json['liters']),
      pricePerLiter: serializer.fromJson<Decimal>(json['pricePerLiter']),
      totalCost: serializer.fromJson<Decimal>(json['totalCost']),
      fullTank: serializer.fromJson<bool>(json['fullTank']),
      fuelType: serializer.fromJson<FuelType>(json['fuelType']),
      source: serializer.fromJson<FuelSource>(json['source']),
      receiptImageUrl: serializer.fromJson<String?>(json['receiptImageUrl']),
      stationName: serializer.fromJson<String?>(json['stationName']),
      stationBrand: serializer.fromJson<String?>(json['stationBrand']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'date': serializer.toJson<DateTime>(date),
      'odometer': serializer.toJson<int>(odometer),
      'liters': serializer.toJson<Decimal>(liters),
      'pricePerLiter': serializer.toJson<Decimal>(pricePerLiter),
      'totalCost': serializer.toJson<Decimal>(totalCost),
      'fullTank': serializer.toJson<bool>(fullTank),
      'fuelType': serializer.toJson<FuelType>(fuelType),
      'source': serializer.toJson<FuelSource>(source),
      'receiptImageUrl': serializer.toJson<String?>(receiptImageUrl),
      'stationName': serializer.toJson<String?>(stationName),
      'stationBrand': serializer.toJson<String?>(stationBrand),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  FuelEntryRow copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    int? odometer,
    Decimal? liters,
    Decimal? pricePerLiter,
    Decimal? totalCost,
    bool? fullTank,
    FuelType? fuelType,
    FuelSource? source,
    Value<String?> receiptImageUrl = const Value.absent(),
    Value<String?> stationName = const Value.absent(),
    Value<String?> stationBrand = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
  }) => FuelEntryRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    date: date ?? this.date,
    odometer: odometer ?? this.odometer,
    liters: liters ?? this.liters,
    pricePerLiter: pricePerLiter ?? this.pricePerLiter,
    totalCost: totalCost ?? this.totalCost,
    fullTank: fullTank ?? this.fullTank,
    fuelType: fuelType ?? this.fuelType,
    source: source ?? this.source,
    receiptImageUrl: receiptImageUrl.present
        ? receiptImageUrl.value
        : this.receiptImageUrl,
    stationName: stationName.present ? stationName.value : this.stationName,
    stationBrand: stationBrand.present ? stationBrand.value : this.stationBrand,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  FuelEntryRow copyWithCompanion(FuelEntriesCompanion data) {
    return FuelEntryRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      date: data.date.present ? data.date.value : this.date,
      odometer: data.odometer.present ? data.odometer.value : this.odometer,
      liters: data.liters.present ? data.liters.value : this.liters,
      pricePerLiter: data.pricePerLiter.present
          ? data.pricePerLiter.value
          : this.pricePerLiter,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      fullTank: data.fullTank.present ? data.fullTank.value : this.fullTank,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      source: data.source.present ? data.source.value : this.source,
      receiptImageUrl: data.receiptImageUrl.present
          ? data.receiptImageUrl.value
          : this.receiptImageUrl,
      stationName: data.stationName.present
          ? data.stationName.value
          : this.stationName,
      stationBrand: data.stationBrand.present
          ? data.stationBrand.value
          : this.stationBrand,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelEntryRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('odometer: $odometer, ')
          ..write('liters: $liters, ')
          ..write('pricePerLiter: $pricePerLiter, ')
          ..write('totalCost: $totalCost, ')
          ..write('fullTank: $fullTank, ')
          ..write('fuelType: $fuelType, ')
          ..write('source: $source, ')
          ..write('receiptImageUrl: $receiptImageUrl, ')
          ..write('stationName: $stationName, ')
          ..write('stationBrand: $stationBrand, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    date,
    odometer,
    liters,
    pricePerLiter,
    totalCost,
    fullTank,
    fuelType,
    source,
    receiptImageUrl,
    stationName,
    stationBrand,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelEntryRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.date == this.date &&
          other.odometer == this.odometer &&
          other.liters == this.liters &&
          other.pricePerLiter == this.pricePerLiter &&
          other.totalCost == this.totalCost &&
          other.fullTank == this.fullTank &&
          other.fuelType == this.fuelType &&
          other.source == this.source &&
          other.receiptImageUrl == this.receiptImageUrl &&
          other.stationName == this.stationName &&
          other.stationBrand == this.stationBrand &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class FuelEntriesCompanion extends UpdateCompanion<FuelEntryRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<DateTime> date;
  final Value<int> odometer;
  final Value<Decimal> liters;
  final Value<Decimal> pricePerLiter;
  final Value<Decimal> totalCost;
  final Value<bool> fullTank;
  final Value<FuelType> fuelType;
  final Value<FuelSource> source;
  final Value<String?> receiptImageUrl;
  final Value<String?> stationName;
  final Value<String?> stationBrand;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const FuelEntriesCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.date = const Value.absent(),
    this.odometer = const Value.absent(),
    this.liters = const Value.absent(),
    this.pricePerLiter = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.fullTank = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.source = const Value.absent(),
    this.receiptImageUrl = const Value.absent(),
    this.stationName = const Value.absent(),
    this.stationBrand = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FuelEntriesCompanion.insert({
    required String id,
    required String vehicleId,
    required DateTime date,
    required int odometer,
    required Decimal liters,
    required Decimal pricePerLiter,
    required Decimal totalCost,
    required bool fullTank,
    required FuelType fuelType,
    required FuelSource source,
    this.receiptImageUrl = const Value.absent(),
    this.stationName = const Value.absent(),
    this.stationBrand = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       date = Value(date),
       odometer = Value(odometer),
       liters = Value(liters),
       pricePerLiter = Value(pricePerLiter),
       totalCost = Value(totalCost),
       fullTank = Value(fullTank),
       fuelType = Value(fuelType),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FuelEntryRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<DateTime>? date,
    Expression<int>? odometer,
    Expression<String>? liters,
    Expression<String>? pricePerLiter,
    Expression<String>? totalCost,
    Expression<bool>? fullTank,
    Expression<String>? fuelType,
    Expression<String>? source,
    Expression<String>? receiptImageUrl,
    Expression<String>? stationName,
    Expression<String>? stationBrand,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (date != null) 'date': date,
      if (odometer != null) 'odometer': odometer,
      if (liters != null) 'liters': liters,
      if (pricePerLiter != null) 'price_per_liter': pricePerLiter,
      if (totalCost != null) 'total_cost': totalCost,
      if (fullTank != null) 'full_tank': fullTank,
      if (fuelType != null) 'fuel_type': fuelType,
      if (source != null) 'source': source,
      if (receiptImageUrl != null) 'receipt_image_url': receiptImageUrl,
      if (stationName != null) 'station_name': stationName,
      if (stationBrand != null) 'station_brand': stationBrand,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FuelEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<DateTime>? date,
    Value<int>? odometer,
    Value<Decimal>? liters,
    Value<Decimal>? pricePerLiter,
    Value<Decimal>? totalCost,
    Value<bool>? fullTank,
    Value<FuelType>? fuelType,
    Value<FuelSource>? source,
    Value<String?>? receiptImageUrl,
    Value<String?>? stationName,
    Value<String?>? stationBrand,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return FuelEntriesCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      odometer: odometer ?? this.odometer,
      liters: liters ?? this.liters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalCost: totalCost ?? this.totalCost,
      fullTank: fullTank ?? this.fullTank,
      fuelType: fuelType ?? this.fuelType,
      source: source ?? this.source,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      stationName: stationName ?? this.stationName,
      stationBrand: stationBrand ?? this.stationBrand,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (odometer.present) {
      map['odometer'] = Variable<int>(odometer.value);
    }
    if (liters.present) {
      map['liters'] = Variable<String>(
        $FuelEntriesTable.$converterliters.toSql(liters.value),
      );
    }
    if (pricePerLiter.present) {
      map['price_per_liter'] = Variable<String>(
        $FuelEntriesTable.$converterpricePerLiter.toSql(pricePerLiter.value),
      );
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<String>(
        $FuelEntriesTable.$convertertotalCost.toSql(totalCost.value),
      );
    }
    if (fullTank.present) {
      map['full_tank'] = Variable<bool>(fullTank.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(
        $FuelEntriesTable.$converterfuelType.toSql(fuelType.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $FuelEntriesTable.$convertersource.toSql(source.value),
      );
    }
    if (receiptImageUrl.present) {
      map['receipt_image_url'] = Variable<String>(receiptImageUrl.value);
    }
    if (stationName.present) {
      map['station_name'] = Variable<String>(stationName.value);
    }
    if (stationBrand.present) {
      map['station_brand'] = Variable<String>(stationBrand.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $FuelEntriesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FuelEntriesCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('odometer: $odometer, ')
          ..write('liters: $liters, ')
          ..write('pricePerLiter: $pricePerLiter, ')
          ..write('totalCost: $totalCost, ')
          ..write('fullTank: $fullTank, ')
          ..write('fuelType: $fuelType, ')
          ..write('source: $source, ')
          ..write('receiptImageUrl: $receiptImageUrl, ')
          ..write('stationName: $stationName, ')
          ..write('stationBrand: $stationBrand, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExpenseCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ExpenseCategory>($ExpensesTable.$convertercategory);
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> amount =
      GeneratedColumn<String>(
        'amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($ExpensesTable.$converteramount);
  static const VerificationMeta _odometerMeta = const VerificationMeta(
    'odometer',
  );
  @override
  late final GeneratedColumn<int> odometer = GeneratedColumn<int>(
    'odometer',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncStatus>($ExpensesTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    date,
    category,
    description,
    amount,
    odometer,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('odometer')) {
      context.handle(
        _odometerMeta,
        odometer.isAcceptableOrUnknown(data['odometer']!, _odometerMeta),
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
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      category: $ExpensesTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      amount: $ExpensesTable.$converteramount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount'],
        )!,
      ),
      odometer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}odometer'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $ExpensesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }

  static TypeConverter<ExpenseCategory, String> $convertercategory =
      const ExpenseCategoryConverter();
  static TypeConverter<Decimal, String> $converteramount =
      const DecimalConverter();
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final String vehicleId;
  final DateTime date;
  final ExpenseCategory category;
  final String description;
  final Decimal amount;
  final int? odometer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  const ExpenseRow({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    this.odometer,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['date'] = Variable<DateTime>(date);
    {
      map['category'] = Variable<String>(
        $ExpensesTable.$convertercategory.toSql(category),
      );
    }
    map['description'] = Variable<String>(description);
    {
      map['amount'] = Variable<String>(
        $ExpensesTable.$converteramount.toSql(amount),
      );
    }
    if (!nullToAbsent || odometer != null) {
      map['odometer'] = Variable<int>(odometer);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    {
      map['sync_status'] = Variable<String>(
        $ExpensesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      date: Value(date),
      category: Value(category),
      description: Value(description),
      amount: Value(amount),
      odometer: odometer == null && nullToAbsent
          ? const Value.absent()
          : Value(odometer),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: serializer.fromJson<ExpenseCategory>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<Decimal>(json['amount']),
      odometer: serializer.fromJson<int?>(json['odometer']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<ExpenseCategory>(category),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<Decimal>(amount),
      'odometer': serializer.toJson<int?>(odometer),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  ExpenseRow copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    ExpenseCategory? category,
    String? description,
    Decimal? amount,
    Value<int?> odometer = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
  }) => ExpenseRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    date: date ?? this.date,
    category: category ?? this.category,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    odometer: odometer.present ? odometer.value : this.odometer,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      odometer: data.odometer.present ? data.odometer.value : this.odometer,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('odometer: $odometer, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    date,
    category,
    description,
    amount,
    odometer,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.date == this.date &&
          other.category == this.category &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.odometer == this.odometer &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<DateTime> date;
  final Value<ExpenseCategory> category;
  final Value<String> description;
  final Value<Decimal> amount;
  final Value<int?> odometer;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.odometer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String vehicleId,
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    required Decimal amount,
    this.odometer = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       date = Value(date),
       category = Value(category),
       description = Value(description),
       amount = Value(amount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<DateTime>? date,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? amount,
    Expression<int>? odometer,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (odometer != null) 'odometer': odometer,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<DateTime>? date,
    Value<ExpenseCategory>? category,
    Value<String>? description,
    Value<Decimal>? amount,
    Value<int?>? odometer,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      odometer: odometer ?? this.odometer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $ExpensesTable.$convertercategory.toSql(category.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(
        $ExpensesTable.$converteramount.toSql(amount.value),
      );
    }
    if (odometer.present) {
      map['odometer'] = Variable<int>(odometer.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $ExpensesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('odometer: $odometer, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReminderType>($RemindersTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueKmMeta = const VerificationMeta('dueKm');
  @override
  late final GeneratedColumn<int> dueKm = GeneratedColumn<int>(
    'due_km',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncStatus>($RemindersTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    type,
    title,
    dueKm,
    dueDate,
    isDone,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_km')) {
      context.handle(
        _dueKmMeta,
        dueKm.isAcceptableOrUnknown(data['due_km']!, _dueKmMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
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
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      type: $RemindersTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      dueKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_km'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $RemindersTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static TypeConverter<ReminderType, String> $convertertype =
      const ReminderTypeConverter();
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final String vehicleId;
  final ReminderType type;
  final String title;
  final int? dueKm;
  final DateTime? dueDate;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  const ReminderRow({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.title,
    this.dueKm,
    this.dueDate,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    {
      map['type'] = Variable<String>(
        $RemindersTable.$convertertype.toSql(type),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || dueKm != null) {
      map['due_km'] = Variable<int>(dueKm);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_done'] = Variable<bool>(isDone);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    {
      map['sync_status'] = Variable<String>(
        $RemindersTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      type: Value(type),
      title: Value(title),
      dueKm: dueKm == null && nullToAbsent
          ? const Value.absent()
          : Value(dueKm),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isDone: Value(isDone),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      type: serializer.fromJson<ReminderType>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      dueKm: serializer.fromJson<int?>(json['dueKm']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'type': serializer.toJson<ReminderType>(type),
      'title': serializer.toJson<String>(title),
      'dueKm': serializer.toJson<int?>(dueKm),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isDone': serializer.toJson<bool>(isDone),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  ReminderRow copyWith({
    String? id,
    String? vehicleId,
    ReminderType? type,
    String? title,
    Value<int?> dueKm = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    bool? isDone,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
  }) => ReminderRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    type: type ?? this.type,
    title: title ?? this.title,
    dueKm: dueKm.present ? dueKm.value : this.dueKm,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isDone: isDone ?? this.isDone,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      dueKm: data.dueKm.present ? data.dueKm.value : this.dueKm,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('dueKm: $dueKm, ')
          ..write('dueDate: $dueDate, ')
          ..write('isDone: $isDone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    type,
    title,
    dueKm,
    dueDate,
    isDone,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.type == this.type &&
          other.title == this.title &&
          other.dueKm == this.dueKm &&
          other.dueDate == this.dueDate &&
          other.isDone == this.isDone &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<ReminderType> type;
  final Value<String> title;
  final Value<int?> dueKm;
  final Value<DateTime?> dueDate;
  final Value<bool> isDone;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.dueKm = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isDone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String vehicleId,
    required ReminderType type,
    required String title,
    this.dueKm = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isDone = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       type = Value(type),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<int>? dueKm,
    Expression<DateTime>? dueDate,
    Expression<bool>? isDone,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (dueKm != null) 'due_km': dueKm,
      if (dueDate != null) 'due_date': dueDate,
      if (isDone != null) 'is_done': isDone,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<ReminderType>? type,
    Value<String>? title,
    Value<int?>? dueKm,
    Value<DateTime?>? dueDate,
    Value<bool>? isDone,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      title: title ?? this.title,
      dueKm: dueKm ?? this.dueKm,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $RemindersTable.$convertertype.toSql(type.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (dueKm.present) {
      map['due_km'] = Variable<int>(dueKm.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $RemindersTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('dueKm: $dueKm, ')
          ..write('dueDate: $dueDate, ')
          ..write('isDone: $isDone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsageQuotaTable extends UsageQuota
    with TableInfo<$UsageQuotaTable, UsageQuotaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageQuotaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanCountMeta = const VerificationMeta(
    'scanCount',
  );
  @override
  late final GeneratedColumn<int> scanCount = GeneratedColumn<int>(
    'scan_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPremiumMeta = const VerificationMeta(
    'isPremium',
  );
  @override
  late final GeneratedColumn<bool> isPremium = GeneratedColumn<bool>(
    'is_premium',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_premium" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [userId, month, scanCount, isPremium];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_quota';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsageQuotaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('scan_count')) {
      context.handle(
        _scanCountMeta,
        scanCount.isAcceptableOrUnknown(data['scan_count']!, _scanCountMeta),
      );
    }
    if (data.containsKey('is_premium')) {
      context.handle(
        _isPremiumMeta,
        isPremium.isAcceptableOrUnknown(data['is_premium']!, _isPremiumMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  UsageQuotaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageQuotaRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      scanCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_count'],
      )!,
      isPremium: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_premium'],
      )!,
    );
  }

  @override
  $UsageQuotaTable createAlias(String alias) {
    return $UsageQuotaTable(attachedDatabase, alias);
  }
}

class UsageQuotaRow extends DataClass implements Insertable<UsageQuotaRow> {
  /// PK: user_id (UUID do Supabase Auth).
  final String userId;
  final String month;
  final int scanCount;
  final bool isPremium;
  const UsageQuotaRow({
    required this.userId,
    required this.month,
    required this.scanCount,
    required this.isPremium,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['month'] = Variable<String>(month);
    map['scan_count'] = Variable<int>(scanCount);
    map['is_premium'] = Variable<bool>(isPremium);
    return map;
  }

  UsageQuotaCompanion toCompanion(bool nullToAbsent) {
    return UsageQuotaCompanion(
      userId: Value(userId),
      month: Value(month),
      scanCount: Value(scanCount),
      isPremium: Value(isPremium),
    );
  }

  factory UsageQuotaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageQuotaRow(
      userId: serializer.fromJson<String>(json['userId']),
      month: serializer.fromJson<String>(json['month']),
      scanCount: serializer.fromJson<int>(json['scanCount']),
      isPremium: serializer.fromJson<bool>(json['isPremium']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'month': serializer.toJson<String>(month),
      'scanCount': serializer.toJson<int>(scanCount),
      'isPremium': serializer.toJson<bool>(isPremium),
    };
  }

  UsageQuotaRow copyWith({
    String? userId,
    String? month,
    int? scanCount,
    bool? isPremium,
  }) => UsageQuotaRow(
    userId: userId ?? this.userId,
    month: month ?? this.month,
    scanCount: scanCount ?? this.scanCount,
    isPremium: isPremium ?? this.isPremium,
  );
  UsageQuotaRow copyWithCompanion(UsageQuotaCompanion data) {
    return UsageQuotaRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      month: data.month.present ? data.month.value : this.month,
      scanCount: data.scanCount.present ? data.scanCount.value : this.scanCount,
      isPremium: data.isPremium.present ? data.isPremium.value : this.isPremium,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageQuotaRow(')
          ..write('userId: $userId, ')
          ..write('month: $month, ')
          ..write('scanCount: $scanCount, ')
          ..write('isPremium: $isPremium')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, month, scanCount, isPremium);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageQuotaRow &&
          other.userId == this.userId &&
          other.month == this.month &&
          other.scanCount == this.scanCount &&
          other.isPremium == this.isPremium);
}

class UsageQuotaCompanion extends UpdateCompanion<UsageQuotaRow> {
  final Value<String> userId;
  final Value<String> month;
  final Value<int> scanCount;
  final Value<bool> isPremium;
  final Value<int> rowid;
  const UsageQuotaCompanion({
    this.userId = const Value.absent(),
    this.month = const Value.absent(),
    this.scanCount = const Value.absent(),
    this.isPremium = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsageQuotaCompanion.insert({
    required String userId,
    required String month,
    this.scanCount = const Value.absent(),
    this.isPremium = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       month = Value(month);
  static Insertable<UsageQuotaRow> custom({
    Expression<String>? userId,
    Expression<String>? month,
    Expression<int>? scanCount,
    Expression<bool>? isPremium,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (month != null) 'month': month,
      if (scanCount != null) 'scan_count': scanCount,
      if (isPremium != null) 'is_premium': isPremium,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsageQuotaCompanion copyWith({
    Value<String>? userId,
    Value<String>? month,
    Value<int>? scanCount,
    Value<bool>? isPremium,
    Value<int>? rowid,
  }) {
    return UsageQuotaCompanion(
      userId: userId ?? this.userId,
      month: month ?? this.month,
      scanCount: scanCount ?? this.scanCount,
      isPremium: isPremium ?? this.isPremium,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (scanCount.present) {
      map['scan_count'] = Variable<int>(scanCount.value);
    }
    if (isPremium.present) {
      map['is_premium'] = Variable<bool>(isPremium.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageQuotaCompanion(')
          ..write('userId: $userId, ')
          ..write('month: $month, ')
          ..write('scanCount: $scanCount, ')
          ..write('isPremium: $isPremium, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FipeCacheTable extends FipeCache
    with TableInfo<$FipeCacheTable, FipeCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FipeCacheTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, expiresAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fipe_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<FipeCacheRow> instance, {
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
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  FipeCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FipeCacheRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $FipeCacheTable createAlias(String alias) {
    return $FipeCacheTable(attachedDatabase, alias);
  }
}

class FipeCacheRow extends DataClass implements Insertable<FipeCacheRow> {
  final String key;
  final String value;
  final DateTime expiresAt;
  const FipeCacheRow({
    required this.key,
    required this.value,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  FipeCacheCompanion toCompanion(bool nullToAbsent) {
    return FipeCacheCompanion(
      key: Value(key),
      value: Value(value),
      expiresAt: Value(expiresAt),
    );
  }

  factory FipeCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FipeCacheRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  FipeCacheRow copyWith({String? key, String? value, DateTime? expiresAt}) =>
      FipeCacheRow(
        key: key ?? this.key,
        value: value ?? this.value,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  FipeCacheRow copyWithCompanion(FipeCacheCompanion data) {
    return FipeCacheRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FipeCacheRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FipeCacheRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.expiresAt == this.expiresAt);
}

class FipeCacheCompanion extends UpdateCompanion<FipeCacheRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const FipeCacheCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FipeCacheCompanion.insert({
    required String key,
    required String value,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       expiresAt = Value(expiresAt);
  static Insertable<FipeCacheRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FipeCacheCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return FipeCacheCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      expiresAt: expiresAt ?? this.expiresAt,
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
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FipeCacheCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FipeHistoryTable extends FipeHistory
    with TableInfo<$FipeHistoryTable, FipeHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FipeHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> value =
      GeneratedColumn<String>(
        'value',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($FipeHistoryTable.$convertervalue);
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [vehicleId, month, value, capturedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fipe_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<FipeHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vehicleId, month};
  @override
  FipeHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FipeHistoryRow(
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      value: $FipeHistoryTable.$convertervalue.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}value'],
        )!,
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
    );
  }

  @override
  $FipeHistoryTable createAlias(String alias) {
    return $FipeHistoryTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertervalue =
      const DecimalConverter();
}

class FipeHistoryRow extends DataClass implements Insertable<FipeHistoryRow> {
  final String vehicleId;
  final String month;
  final Decimal value;
  final DateTime capturedAt;
  const FipeHistoryRow({
    required this.vehicleId,
    required this.month,
    required this.value,
    required this.capturedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['month'] = Variable<String>(month);
    {
      map['value'] = Variable<String>(
        $FipeHistoryTable.$convertervalue.toSql(value),
      );
    }
    map['captured_at'] = Variable<DateTime>(capturedAt);
    return map;
  }

  FipeHistoryCompanion toCompanion(bool nullToAbsent) {
    return FipeHistoryCompanion(
      vehicleId: Value(vehicleId),
      month: Value(month),
      value: Value(value),
      capturedAt: Value(capturedAt),
    );
  }

  factory FipeHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FipeHistoryRow(
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      month: serializer.fromJson<String>(json['month']),
      value: serializer.fromJson<Decimal>(json['value']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vehicleId': serializer.toJson<String>(vehicleId),
      'month': serializer.toJson<String>(month),
      'value': serializer.toJson<Decimal>(value),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
    };
  }

  FipeHistoryRow copyWith({
    String? vehicleId,
    String? month,
    Decimal? value,
    DateTime? capturedAt,
  }) => FipeHistoryRow(
    vehicleId: vehicleId ?? this.vehicleId,
    month: month ?? this.month,
    value: value ?? this.value,
    capturedAt: capturedAt ?? this.capturedAt,
  );
  FipeHistoryRow copyWithCompanion(FipeHistoryCompanion data) {
    return FipeHistoryRow(
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      month: data.month.present ? data.month.value : this.month,
      value: data.value.present ? data.value.value : this.value,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FipeHistoryRow(')
          ..write('vehicleId: $vehicleId, ')
          ..write('month: $month, ')
          ..write('value: $value, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(vehicleId, month, value, capturedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FipeHistoryRow &&
          other.vehicleId == this.vehicleId &&
          other.month == this.month &&
          other.value == this.value &&
          other.capturedAt == this.capturedAt);
}

class FipeHistoryCompanion extends UpdateCompanion<FipeHistoryRow> {
  final Value<String> vehicleId;
  final Value<String> month;
  final Value<Decimal> value;
  final Value<DateTime> capturedAt;
  final Value<int> rowid;
  const FipeHistoryCompanion({
    this.vehicleId = const Value.absent(),
    this.month = const Value.absent(),
    this.value = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FipeHistoryCompanion.insert({
    required String vehicleId,
    required String month,
    required Decimal value,
    required DateTime capturedAt,
    this.rowid = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       month = Value(month),
       value = Value(value),
       capturedAt = Value(capturedAt);
  static Insertable<FipeHistoryRow> custom({
    Expression<String>? vehicleId,
    Expression<String>? month,
    Expression<String>? value,
    Expression<DateTime>? capturedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (month != null) 'month': month,
      if (value != null) 'value': value,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FipeHistoryCompanion copyWith({
    Value<String>? vehicleId,
    Value<String>? month,
    Value<Decimal>? value,
    Value<DateTime>? capturedAt,
    Value<int>? rowid,
  }) {
    return FipeHistoryCompanion(
      vehicleId: vehicleId ?? this.vehicleId,
      month: month ?? this.month,
      value: value ?? this.value,
      capturedAt: capturedAt ?? this.capturedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(
        $FipeHistoryTable.$convertervalue.toSql(value.value),
      );
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FipeHistoryCompanion(')
          ..write('vehicleId: $vehicleId, ')
          ..write('month: $month, ')
          ..write('value: $value, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cnhNumberMeta = const VerificationMeta(
    'cnhNumber',
  );
  @override
  late final GeneratedColumn<String> cnhNumber = GeneratedColumn<String>(
    'cnh_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cnhCategoryMeta = const VerificationMeta(
    'cnhCategory',
  );
  @override
  late final GeneratedColumn<String> cnhCategory = GeneratedColumn<String>(
    'cnh_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cnhExpiresAtMeta = const VerificationMeta(
    'cnhExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> cnhExpiresAt = GeneratedColumn<DateTime>(
    'cnh_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncStatus>($UserProfileTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    cnhNumber,
    cnhCategory,
    cnhExpiresAt,
    createdAt,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('cnh_number')) {
      context.handle(
        _cnhNumberMeta,
        cnhNumber.isAcceptableOrUnknown(data['cnh_number']!, _cnhNumberMeta),
      );
    }
    if (data.containsKey('cnh_category')) {
      context.handle(
        _cnhCategoryMeta,
        cnhCategory.isAcceptableOrUnknown(
          data['cnh_category']!,
          _cnhCategoryMeta,
        ),
      );
    }
    if (data.containsKey('cnh_expires_at')) {
      context.handle(
        _cnhExpiresAtMeta,
        cnhExpiresAt.isAcceptableOrUnknown(
          data['cnh_expires_at']!,
          _cnhExpiresAtMeta,
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
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      cnhNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cnh_number'],
      ),
      cnhCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cnh_category'],
      ),
      cnhExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cnh_expires_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $UserProfileTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  /// PK: user_id (UUID do Supabase Auth — não vehicleId).
  final String userId;
  final String? cnhNumber;
  final String? cnhCategory;
  final DateTime? cnhExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  const UserProfileRow({
    required this.userId,
    this.cnhNumber,
    this.cnhCategory,
    this.cnhExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || cnhNumber != null) {
      map['cnh_number'] = Variable<String>(cnhNumber);
    }
    if (!nullToAbsent || cnhCategory != null) {
      map['cnh_category'] = Variable<String>(cnhCategory);
    }
    if (!nullToAbsent || cnhExpiresAt != null) {
      map['cnh_expires_at'] = Variable<DateTime>(cnhExpiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $UserProfileTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      userId: Value(userId),
      cnhNumber: cnhNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(cnhNumber),
      cnhCategory: cnhCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(cnhCategory),
      cnhExpiresAt: cnhExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cnhExpiresAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      userId: serializer.fromJson<String>(json['userId']),
      cnhNumber: serializer.fromJson<String?>(json['cnhNumber']),
      cnhCategory: serializer.fromJson<String?>(json['cnhCategory']),
      cnhExpiresAt: serializer.fromJson<DateTime?>(json['cnhExpiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'cnhNumber': serializer.toJson<String?>(cnhNumber),
      'cnhCategory': serializer.toJson<String?>(cnhCategory),
      'cnhExpiresAt': serializer.toJson<DateTime?>(cnhExpiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  UserProfileRow copyWith({
    String? userId,
    Value<String?> cnhNumber = const Value.absent(),
    Value<String?> cnhCategory = const Value.absent(),
    Value<DateTime?> cnhExpiresAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) => UserProfileRow(
    userId: userId ?? this.userId,
    cnhNumber: cnhNumber.present ? cnhNumber.value : this.cnhNumber,
    cnhCategory: cnhCategory.present ? cnhCategory.value : this.cnhCategory,
    cnhExpiresAt: cnhExpiresAt.present ? cnhExpiresAt.value : this.cnhExpiresAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  UserProfileRow copyWithCompanion(UserProfileCompanion data) {
    return UserProfileRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      cnhNumber: data.cnhNumber.present ? data.cnhNumber.value : this.cnhNumber,
      cnhCategory: data.cnhCategory.present
          ? data.cnhCategory.value
          : this.cnhCategory,
      cnhExpiresAt: data.cnhExpiresAt.present
          ? data.cnhExpiresAt.value
          : this.cnhExpiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('userId: $userId, ')
          ..write('cnhNumber: $cnhNumber, ')
          ..write('cnhCategory: $cnhCategory, ')
          ..write('cnhExpiresAt: $cnhExpiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    cnhNumber,
    cnhCategory,
    cnhExpiresAt,
    createdAt,
    updatedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.userId == this.userId &&
          other.cnhNumber == this.cnhNumber &&
          other.cnhCategory == this.cnhCategory &&
          other.cnhExpiresAt == this.cnhExpiresAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<String> userId;
  final Value<String?> cnhNumber;
  final Value<String?> cnhCategory;
  final Value<DateTime?> cnhExpiresAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const UserProfileCompanion({
    this.userId = const Value.absent(),
    this.cnhNumber = const Value.absent(),
    this.cnhCategory = const Value.absent(),
    this.cnhExpiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfileCompanion.insert({
    required String userId,
    this.cnhNumber = const Value.absent(),
    this.cnhCategory = const Value.absent(),
    this.cnhExpiresAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserProfileRow> custom({
    Expression<String>? userId,
    Expression<String>? cnhNumber,
    Expression<String>? cnhCategory,
    Expression<DateTime>? cnhExpiresAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (cnhNumber != null) 'cnh_number': cnhNumber,
      if (cnhCategory != null) 'cnh_category': cnhCategory,
      if (cnhExpiresAt != null) 'cnh_expires_at': cnhExpiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfileCompanion copyWith({
    Value<String>? userId,
    Value<String?>? cnhNumber,
    Value<String?>? cnhCategory,
    Value<DateTime?>? cnhExpiresAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return UserProfileCompanion(
      userId: userId ?? this.userId,
      cnhNumber: cnhNumber ?? this.cnhNumber,
      cnhCategory: cnhCategory ?? this.cnhCategory,
      cnhExpiresAt: cnhExpiresAt ?? this.cnhExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cnhNumber.present) {
      map['cnh_number'] = Variable<String>(cnhNumber.value);
    }
    if (cnhCategory.present) {
      map['cnh_category'] = Variable<String>(cnhCategory.value);
    }
    if (cnhExpiresAt.present) {
      map['cnh_expires_at'] = Variable<DateTime>(cnhExpiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $UserProfileTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('userId: $userId, ')
          ..write('cnhNumber: $cnhNumber, ')
          ..write('cnhCategory: $cnhCategory, ')
          ..write('cnhExpiresAt: $cnhExpiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinesTable extends Fines with TableInfo<$FinesTable, FineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoNumberMeta = const VerificationMeta(
    'autoNumber',
  );
  @override
  late final GeneratedColumn<String> autoNumber = GeneratedColumn<String>(
    'auto_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> amount =
      GeneratedColumn<String>(
        'amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($FinesTable.$converteramount);
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidMeta = const VerificationMeta('paid');
  @override
  late final GeneratedColumn<bool> paid = GeneratedColumn<bool>(
    'paid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncStatus>($FinesTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    autoNumber,
    issuedAt,
    description,
    amount,
    dueDate,
    paid,
    points,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fines';
  @override
  VerificationContext validateIntegrity(
    Insertable<FineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('auto_number')) {
      context.handle(
        _autoNumberMeta,
        autoNumber.isAcceptableOrUnknown(data['auto_number']!, _autoNumberMeta),
      );
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('paid')) {
      context.handle(
        _paidMeta,
        paid.isAcceptableOrUnknown(data['paid']!, _paidMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
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
  FineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      autoNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auto_number'],
      ),
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      amount: $FinesTable.$converteramount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount'],
        )!,
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      paid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paid'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $FinesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $FinesTable createAlias(String alias) {
    return $FinesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converteramount =
      const DecimalConverter();
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class FineRow extends DataClass implements Insertable<FineRow> {
  final String id;
  final String vehicleId;
  final String? autoNumber;
  final DateTime issuedAt;
  final String description;
  final Decimal amount;
  final DateTime? dueDate;
  final bool paid;
  final int? points;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  const FineRow({
    required this.id,
    required this.vehicleId,
    this.autoNumber,
    required this.issuedAt,
    required this.description,
    required this.amount,
    this.dueDate,
    required this.paid,
    this.points,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    if (!nullToAbsent || autoNumber != null) {
      map['auto_number'] = Variable<String>(autoNumber);
    }
    map['issued_at'] = Variable<DateTime>(issuedAt);
    map['description'] = Variable<String>(description);
    {
      map['amount'] = Variable<String>(
        $FinesTable.$converteramount.toSql(amount),
      );
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['paid'] = Variable<bool>(paid);
    if (!nullToAbsent || points != null) {
      map['points'] = Variable<int>(points);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    {
      map['sync_status'] = Variable<String>(
        $FinesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  FinesCompanion toCompanion(bool nullToAbsent) {
    return FinesCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      autoNumber: autoNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(autoNumber),
      issuedAt: Value(issuedAt),
      description: Value(description),
      amount: Value(amount),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      paid: Value(paid),
      points: points == null && nullToAbsent
          ? const Value.absent()
          : Value(points),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory FineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FineRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      autoNumber: serializer.fromJson<String?>(json['autoNumber']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<Decimal>(json['amount']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      paid: serializer.fromJson<bool>(json['paid']),
      points: serializer.fromJson<int?>(json['points']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'autoNumber': serializer.toJson<String?>(autoNumber),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<Decimal>(amount),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'paid': serializer.toJson<bool>(paid),
      'points': serializer.toJson<int?>(points),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  FineRow copyWith({
    String? id,
    String? vehicleId,
    Value<String?> autoNumber = const Value.absent(),
    DateTime? issuedAt,
    String? description,
    Decimal? amount,
    Value<DateTime?> dueDate = const Value.absent(),
    bool? paid,
    Value<int?> points = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
  }) => FineRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    autoNumber: autoNumber.present ? autoNumber.value : this.autoNumber,
    issuedAt: issuedAt ?? this.issuedAt,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    paid: paid ?? this.paid,
    points: points.present ? points.value : this.points,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  FineRow copyWithCompanion(FinesCompanion data) {
    return FineRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      autoNumber: data.autoNumber.present
          ? data.autoNumber.value
          : this.autoNumber,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      description: data.description.present
          ? data.description.value
          : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      paid: data.paid.present ? data.paid.value : this.paid,
      points: data.points.present ? data.points.value : this.points,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FineRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('autoNumber: $autoNumber, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('dueDate: $dueDate, ')
          ..write('paid: $paid, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    autoNumber,
    issuedAt,
    description,
    amount,
    dueDate,
    paid,
    points,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FineRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.autoNumber == this.autoNumber &&
          other.issuedAt == this.issuedAt &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.dueDate == this.dueDate &&
          other.paid == this.paid &&
          other.points == this.points &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class FinesCompanion extends UpdateCompanion<FineRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<String?> autoNumber;
  final Value<DateTime> issuedAt;
  final Value<String> description;
  final Value<Decimal> amount;
  final Value<DateTime?> dueDate;
  final Value<bool> paid;
  final Value<int?> points;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const FinesCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.autoNumber = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.paid = const Value.absent(),
    this.points = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinesCompanion.insert({
    required String id,
    required String vehicleId,
    this.autoNumber = const Value.absent(),
    required DateTime issuedAt,
    required String description,
    required Decimal amount,
    this.dueDate = const Value.absent(),
    this.paid = const Value.absent(),
    this.points = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       issuedAt = Value(issuedAt),
       description = Value(description),
       amount = Value(amount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FineRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<String>? autoNumber,
    Expression<DateTime>? issuedAt,
    Expression<String>? description,
    Expression<String>? amount,
    Expression<DateTime>? dueDate,
    Expression<bool>? paid,
    Expression<int>? points,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (autoNumber != null) 'auto_number': autoNumber,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (dueDate != null) 'due_date': dueDate,
      if (paid != null) 'paid': paid,
      if (points != null) 'points': points,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinesCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<String?>? autoNumber,
    Value<DateTime>? issuedAt,
    Value<String>? description,
    Value<Decimal>? amount,
    Value<DateTime?>? dueDate,
    Value<bool>? paid,
    Value<int?>? points,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return FinesCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      autoNumber: autoNumber ?? this.autoNumber,
      issuedAt: issuedAt ?? this.issuedAt,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paid: paid ?? this.paid,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (autoNumber.present) {
      map['auto_number'] = Variable<String>(autoNumber.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(
        $FinesTable.$converteramount.toSql(amount.value),
      );
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (paid.present) {
      map['paid'] = Variable<bool>(paid.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $FinesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinesCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('autoNumber: $autoNumber, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('dueDate: $dueDate, ')
          ..write('paid: $paid, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InsurancesTable extends Insurances
    with TableInfo<$InsurancesTable, InsuranceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InsurancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _insurerMeta = const VerificationMeta(
    'insurer',
  );
  @override
  late final GeneratedColumn<String> insurer = GeneratedColumn<String>(
    'insurer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _policyNumberMeta = const VerificationMeta(
    'policyNumber',
  );
  @override
  late final GeneratedColumn<String> policyNumber = GeneratedColumn<String>(
    'policy_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
    'ends_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> premiumPaid =
      GeneratedColumn<String>(
        'premium_paid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($InsurancesTable.$converterpremiumPaidn);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncStatus>($InsurancesTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    insurer,
    policyNumber,
    startsAt,
    endsAt,
    premiumPaid,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'insurances';
  @override
  VerificationContext validateIntegrity(
    Insertable<InsuranceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('insurer')) {
      context.handle(
        _insurerMeta,
        insurer.isAcceptableOrUnknown(data['insurer']!, _insurerMeta),
      );
    }
    if (data.containsKey('policy_number')) {
      context.handle(
        _policyNumberMeta,
        policyNumber.isAcceptableOrUnknown(
          data['policy_number']!,
          _policyNumberMeta,
        ),
      );
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endsAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  InsuranceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InsuranceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      insurer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insurer'],
      ),
      policyNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}policy_number'],
      ),
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_at'],
      )!,
      premiumPaid: $InsurancesTable.$converterpremiumPaidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}premium_paid'],
        ),
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $InsurancesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $InsurancesTable createAlias(String alias) {
    return $InsurancesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterpremiumPaid =
      const DecimalConverter();
  static TypeConverter<Decimal?, String?> $converterpremiumPaidn =
      NullAwareTypeConverter.wrap($converterpremiumPaid);
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class InsuranceRow extends DataClass implements Insertable<InsuranceRow> {
  final String id;
  final String vehicleId;
  final String? insurer;
  final String? policyNumber;
  final DateTime startsAt;
  final DateTime endsAt;
  final Decimal? premiumPaid;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  const InsuranceRow({
    required this.id,
    required this.vehicleId,
    this.insurer,
    this.policyNumber,
    required this.startsAt,
    required this.endsAt,
    this.premiumPaid,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    if (!nullToAbsent || insurer != null) {
      map['insurer'] = Variable<String>(insurer);
    }
    if (!nullToAbsent || policyNumber != null) {
      map['policy_number'] = Variable<String>(policyNumber);
    }
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['ends_at'] = Variable<DateTime>(endsAt);
    if (!nullToAbsent || premiumPaid != null) {
      map['premium_paid'] = Variable<String>(
        $InsurancesTable.$converterpremiumPaidn.toSql(premiumPaid),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    {
      map['sync_status'] = Variable<String>(
        $InsurancesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  InsurancesCompanion toCompanion(bool nullToAbsent) {
    return InsurancesCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      insurer: insurer == null && nullToAbsent
          ? const Value.absent()
          : Value(insurer),
      policyNumber: policyNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(policyNumber),
      startsAt: Value(startsAt),
      endsAt: Value(endsAt),
      premiumPaid: premiumPaid == null && nullToAbsent
          ? const Value.absent()
          : Value(premiumPaid),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory InsuranceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InsuranceRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      insurer: serializer.fromJson<String?>(json['insurer']),
      policyNumber: serializer.fromJson<String?>(json['policyNumber']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime>(json['endsAt']),
      premiumPaid: serializer.fromJson<Decimal?>(json['premiumPaid']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'insurer': serializer.toJson<String?>(insurer),
      'policyNumber': serializer.toJson<String?>(policyNumber),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'endsAt': serializer.toJson<DateTime>(endsAt),
      'premiumPaid': serializer.toJson<Decimal?>(premiumPaid),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  InsuranceRow copyWith({
    String? id,
    String? vehicleId,
    Value<String?> insurer = const Value.absent(),
    Value<String?> policyNumber = const Value.absent(),
    DateTime? startsAt,
    DateTime? endsAt,
    Value<Decimal?> premiumPaid = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
  }) => InsuranceRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    insurer: insurer.present ? insurer.value : this.insurer,
    policyNumber: policyNumber.present ? policyNumber.value : this.policyNumber,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    premiumPaid: premiumPaid.present ? premiumPaid.value : this.premiumPaid,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  InsuranceRow copyWithCompanion(InsurancesCompanion data) {
    return InsuranceRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      insurer: data.insurer.present ? data.insurer.value : this.insurer,
      policyNumber: data.policyNumber.present
          ? data.policyNumber.value
          : this.policyNumber,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      premiumPaid: data.premiumPaid.present
          ? data.premiumPaid.value
          : this.premiumPaid,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InsuranceRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('insurer: $insurer, ')
          ..write('policyNumber: $policyNumber, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('premiumPaid: $premiumPaid, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    insurer,
    policyNumber,
    startsAt,
    endsAt,
    premiumPaid,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InsuranceRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.insurer == this.insurer &&
          other.policyNumber == this.policyNumber &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.premiumPaid == this.premiumPaid &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class InsurancesCompanion extends UpdateCompanion<InsuranceRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<String?> insurer;
  final Value<String?> policyNumber;
  final Value<DateTime> startsAt;
  final Value<DateTime> endsAt;
  final Value<Decimal?> premiumPaid;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const InsurancesCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.insurer = const Value.absent(),
    this.policyNumber = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.premiumPaid = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InsurancesCompanion.insert({
    required String id,
    required String vehicleId,
    this.insurer = const Value.absent(),
    this.policyNumber = const Value.absent(),
    required DateTime startsAt,
    required DateTime endsAt,
    this.premiumPaid = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       startsAt = Value(startsAt),
       endsAt = Value(endsAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InsuranceRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<String>? insurer,
    Expression<String>? policyNumber,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<String>? premiumPaid,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (insurer != null) 'insurer': insurer,
      if (policyNumber != null) 'policy_number': policyNumber,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (premiumPaid != null) 'premium_paid': premiumPaid,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InsurancesCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<String?>? insurer,
    Value<String?>? policyNumber,
    Value<DateTime>? startsAt,
    Value<DateTime>? endsAt,
    Value<Decimal?>? premiumPaid,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return InsurancesCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      insurer: insurer ?? this.insurer,
      policyNumber: policyNumber ?? this.policyNumber,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      premiumPaid: premiumPaid ?? this.premiumPaid,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (insurer.present) {
      map['insurer'] = Variable<String>(insurer.value);
    }
    if (policyNumber.present) {
      map['policy_number'] = Variable<String>(policyNumber.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (premiumPaid.present) {
      map['premium_paid'] = Variable<String>(
        $InsurancesTable.$converterpremiumPaidn.toSql(premiumPaid.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $InsurancesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InsurancesCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('insurer: $insurer, ')
          ..write('policyNumber: $policyNumber, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('premiumPaid: $premiumPaid, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
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
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    role,
    content,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
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
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  final String id;
  final String vehicleId;
  final String role;
  final String content;
  final DateTime createdAt;
  const ChatMessageRow({
    required this.id,
    required this.vehicleId,
    required this.role,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessageRow copyWith({
    String? id,
    String? vehicleId,
    String? role,
    String? content,
    DateTime? createdAt,
  }) => ChatMessageRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    role: role ?? this.role,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatMessageRow copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vehicleId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String vehicleId,
    required String role,
    required String content,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<ChatMessageRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<String>? role,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      role: role ?? this.role,
      content: content ?? this.content,
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
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
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
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsLogTable extends NotificationsLog
    with TableInfo<$NotificationsLogTable, NotificationLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    category,
    sentAt,
    title,
    body,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $NotificationsLogTable createAlias(String alias) {
    return $NotificationsLogTable(attachedDatabase, alias);
  }
}

class NotificationLogRow extends DataClass
    implements Insertable<NotificationLogRow> {
  final String id;
  final String vehicleId;
  final String category;
  final DateTime sentAt;
  final String title;
  final String body;
  const NotificationLogRow({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.sentAt,
    required this.title,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['category'] = Variable<String>(category);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    return map;
  }

  NotificationsLogCompanion toCompanion(bool nullToAbsent) {
    return NotificationsLogCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      category: Value(category),
      sentAt: Value(sentAt),
      title: Value(title),
      body: Value(body),
    );
  }

  factory NotificationLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationLogRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      category: serializer.fromJson<String>(json['category']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'category': serializer.toJson<String>(category),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
    };
  }

  NotificationLogRow copyWith({
    String? id,
    String? vehicleId,
    String? category,
    DateTime? sentAt,
    String? title,
    String? body,
  }) => NotificationLogRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    category: category ?? this.category,
    sentAt: sentAt ?? this.sentAt,
    title: title ?? this.title,
    body: body ?? this.body,
  );
  NotificationLogRow copyWithCompanion(NotificationsLogCompanion data) {
    return NotificationLogRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      category: data.category.present ? data.category.value : this.category,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('category: $category, ')
          ..write('sentAt: $sentAt, ')
          ..write('title: $title, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vehicleId, category, sentAt, title, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationLogRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.category == this.category &&
          other.sentAt == this.sentAt &&
          other.title == this.title &&
          other.body == this.body);
}

class NotificationsLogCompanion extends UpdateCompanion<NotificationLogRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<String> category;
  final Value<DateTime> sentAt;
  final Value<String> title;
  final Value<String> body;
  final Value<int> rowid;
  const NotificationsLogCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.category = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsLogCompanion.insert({
    required String id,
    required String vehicleId,
    required String category,
    required DateTime sentAt,
    required String title,
    required String body,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       category = Value(category),
       sentAt = Value(sentAt),
       title = Value(title),
       body = Value(body);
  static Insertable<NotificationLogRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<String>? category,
    Expression<DateTime>? sentAt,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (category != null) 'category': category,
      if (sentAt != null) 'sent_at': sentAt,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsLogCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<String>? category,
    Value<DateTime>? sentAt,
    Value<String>? title,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return NotificationsLogCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      category: category ?? this.category,
      sentAt: sentAt ?? this.sentAt,
      title: title ?? this.title,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsLogCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('category: $category, ')
          ..write('sentAt: $sentAt, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FiscalLookupCacheTable extends FiscalLookupCache
    with TableInfo<$FiscalLookupCacheTable, FiscalLookupCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiscalLookupCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
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
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, value, expiresAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fiscal_lookup_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<FiscalLookupCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  FiscalLookupCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FiscalLookupCacheRow(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $FiscalLookupCacheTable createAlias(String alias) {
    return $FiscalLookupCacheTable(attachedDatabase, alias);
  }
}

class FiscalLookupCacheRow extends DataClass
    implements Insertable<FiscalLookupCacheRow> {
  final String cacheKey;
  final String value;
  final DateTime expiresAt;
  const FiscalLookupCacheRow({
    required this.cacheKey,
    required this.value,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['value'] = Variable<String>(value);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  FiscalLookupCacheCompanion toCompanion(bool nullToAbsent) {
    return FiscalLookupCacheCompanion(
      cacheKey: Value(cacheKey),
      value: Value(value),
      expiresAt: Value(expiresAt),
    );
  }

  factory FiscalLookupCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FiscalLookupCacheRow(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      value: serializer.fromJson<String>(json['value']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'value': serializer.toJson<String>(value),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  FiscalLookupCacheRow copyWith({
    String? cacheKey,
    String? value,
    DateTime? expiresAt,
  }) => FiscalLookupCacheRow(
    cacheKey: cacheKey ?? this.cacheKey,
    value: value ?? this.value,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  FiscalLookupCacheRow copyWithCompanion(FiscalLookupCacheCompanion data) {
    return FiscalLookupCacheRow(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      value: data.value.present ? data.value.value : this.value,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FiscalLookupCacheRow(')
          ..write('cacheKey: $cacheKey, ')
          ..write('value: $value, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, value, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiscalLookupCacheRow &&
          other.cacheKey == this.cacheKey &&
          other.value == this.value &&
          other.expiresAt == this.expiresAt);
}

class FiscalLookupCacheCompanion extends UpdateCompanion<FiscalLookupCacheRow> {
  final Value<String> cacheKey;
  final Value<String> value;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const FiscalLookupCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.value = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FiscalLookupCacheCompanion.insert({
    required String cacheKey,
    required String value,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       value = Value(value),
       expiresAt = Value(expiresAt);
  static Insertable<FiscalLookupCacheRow> custom({
    Expression<String>? cacheKey,
    Expression<String>? value,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (value != null) 'value': value,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FiscalLookupCacheCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? value,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return FiscalLookupCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      value: value ?? this.value,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiscalLookupCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('value: $value, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $FuelEntriesTable fuelEntries = $FuelEntriesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $UsageQuotaTable usageQuota = $UsageQuotaTable(this);
  late final $FipeCacheTable fipeCache = $FipeCacheTable(this);
  late final $FipeHistoryTable fipeHistory = $FipeHistoryTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $FinesTable fines = $FinesTable(this);
  late final $InsurancesTable insurances = $InsurancesTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $NotificationsLogTable notificationsLog = $NotificationsLogTable(
    this,
  );
  late final $FiscalLookupCacheTable fiscalLookupCache =
      $FiscalLookupCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vehicles,
    fuelEntries,
    expenses,
    reminders,
    usageQuota,
    fipeCache,
    fipeHistory,
    userProfile,
    fines,
    insurances,
    chatMessages,
    notificationsLog,
    fiscalLookupCache,
  ];
}

typedef $$VehiclesTableCreateCompanionBuilder =
    VehiclesCompanion Function({
      required String id,
      required String userId,
      required String nickname,
      Value<String?> make,
      Value<String?> model,
      Value<int?> year,
      Value<String?> uf,
      Value<String?> color,
      Value<VehicleType> type,
      Value<int?> engineDisplacementCc,
      Value<Decimal?> tankCapacityL,
      Value<int?> horsepower,
      Value<String?> fipeCode,
      Value<Decimal?> fipeValue,
      Value<String?> fipeReferenceMonth,
      Value<String?> plate,
      Value<String?> renavam,
      Value<String?> chassi,
      required FuelType fuelType,
      required int initialOdometer,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });
typedef $$VehiclesTableUpdateCompanionBuilder =
    VehiclesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> nickname,
      Value<String?> make,
      Value<String?> model,
      Value<int?> year,
      Value<String?> uf,
      Value<String?> color,
      Value<VehicleType> type,
      Value<int?> engineDisplacementCc,
      Value<Decimal?> tankCapacityL,
      Value<int?> horsepower,
      Value<String?> fipeCode,
      Value<Decimal?> fipeValue,
      Value<String?> fipeReferenceMonth,
      Value<String?> plate,
      Value<String?> renavam,
      Value<String?> chassi,
      Value<FuelType> fuelType,
      Value<int> initialOdometer,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uf => $composableBuilder(
    column: $table.uf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<VehicleType, VehicleType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get engineDisplacementCc => $composableBuilder(
    column: $table.engineDisplacementCc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get tankCapacityL =>
      $composableBuilder(
        column: $table.tankCapacityL,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get horsepower => $composableBuilder(
    column: $table.horsepower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fipeCode => $composableBuilder(
    column: $table.fipeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get fipeValue =>
      $composableBuilder(
        column: $table.fipeValue,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get fipeReferenceMonth => $composableBuilder(
    column: $table.fipeReferenceMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plate => $composableBuilder(
    column: $table.plate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renavam => $composableBuilder(
    column: $table.renavam,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chassi => $composableBuilder(
    column: $table.chassi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FuelType, FuelType, String> get fuelType =>
      $composableBuilder(
        column: $table.fuelType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get initialOdometer => $composableBuilder(
    column: $table.initialOdometer,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uf => $composableBuilder(
    column: $table.uf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get engineDisplacementCc => $composableBuilder(
    column: $table.engineDisplacementCc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tankCapacityL => $composableBuilder(
    column: $table.tankCapacityL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get horsepower => $composableBuilder(
    column: $table.horsepower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fipeCode => $composableBuilder(
    column: $table.fipeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fipeValue => $composableBuilder(
    column: $table.fipeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fipeReferenceMonth => $composableBuilder(
    column: $table.fipeReferenceMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plate => $composableBuilder(
    column: $table.plate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renavam => $composableBuilder(
    column: $table.renavam,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chassi => $composableBuilder(
    column: $table.chassi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialOdometer => $composableBuilder(
    column: $table.initialOdometer,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get make =>
      $composableBuilder(column: $table.make, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get uf =>
      $composableBuilder(column: $table.uf, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumnWithTypeConverter<VehicleType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get engineDisplacementCc => $composableBuilder(
    column: $table.engineDisplacementCc,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal?, String> get tankCapacityL =>
      $composableBuilder(
        column: $table.tankCapacityL,
        builder: (column) => column,
      );

  GeneratedColumn<int> get horsepower => $composableBuilder(
    column: $table.horsepower,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fipeCode =>
      $composableBuilder(column: $table.fipeCode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal?, String> get fipeValue =>
      $composableBuilder(column: $table.fipeValue, builder: (column) => column);

  GeneratedColumn<String> get fipeReferenceMonth => $composableBuilder(
    column: $table.fipeReferenceMonth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plate =>
      $composableBuilder(column: $table.plate, builder: (column) => column);

  GeneratedColumn<String> get renavam =>
      $composableBuilder(column: $table.renavam, builder: (column) => column);

  GeneratedColumn<String> get chassi =>
      $composableBuilder(column: $table.chassi, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FuelType, String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<int> get initialOdometer => $composableBuilder(
    column: $table.initialOdometer,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          VehicleRow,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (
            VehicleRow,
            BaseReferences<_$AppDatabase, $VehiclesTable, VehicleRow>,
          ),
          VehicleRow,
          PrefetchHooks Function()
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String?> make = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> uf = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<VehicleType> type = const Value.absent(),
                Value<int?> engineDisplacementCc = const Value.absent(),
                Value<Decimal?> tankCapacityL = const Value.absent(),
                Value<int?> horsepower = const Value.absent(),
                Value<String?> fipeCode = const Value.absent(),
                Value<Decimal?> fipeValue = const Value.absent(),
                Value<String?> fipeReferenceMonth = const Value.absent(),
                Value<String?> plate = const Value.absent(),
                Value<String?> renavam = const Value.absent(),
                Value<String?> chassi = const Value.absent(),
                Value<FuelType> fuelType = const Value.absent(),
                Value<int> initialOdometer = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                userId: userId,
                nickname: nickname,
                make: make,
                model: model,
                year: year,
                uf: uf,
                color: color,
                type: type,
                engineDisplacementCc: engineDisplacementCc,
                tankCapacityL: tankCapacityL,
                horsepower: horsepower,
                fipeCode: fipeCode,
                fipeValue: fipeValue,
                fipeReferenceMonth: fipeReferenceMonth,
                plate: plate,
                renavam: renavam,
                chassi: chassi,
                fuelType: fuelType,
                initialOdometer: initialOdometer,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String nickname,
                Value<String?> make = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> uf = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<VehicleType> type = const Value.absent(),
                Value<int?> engineDisplacementCc = const Value.absent(),
                Value<Decimal?> tankCapacityL = const Value.absent(),
                Value<int?> horsepower = const Value.absent(),
                Value<String?> fipeCode = const Value.absent(),
                Value<Decimal?> fipeValue = const Value.absent(),
                Value<String?> fipeReferenceMonth = const Value.absent(),
                Value<String?> plate = const Value.absent(),
                Value<String?> renavam = const Value.absent(),
                Value<String?> chassi = const Value.absent(),
                required FuelType fuelType,
                required int initialOdometer,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion.insert(
                id: id,
                userId: userId,
                nickname: nickname,
                make: make,
                model: model,
                year: year,
                uf: uf,
                color: color,
                type: type,
                engineDisplacementCc: engineDisplacementCc,
                tankCapacityL: tankCapacityL,
                horsepower: horsepower,
                fipeCode: fipeCode,
                fipeValue: fipeValue,
                fipeReferenceMonth: fipeReferenceMonth,
                plate: plate,
                renavam: renavam,
                chassi: chassi,
                fuelType: fuelType,
                initialOdometer: initialOdometer,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      VehicleRow,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (VehicleRow, BaseReferences<_$AppDatabase, $VehiclesTable, VehicleRow>),
      VehicleRow,
      PrefetchHooks Function()
    >;
typedef $$FuelEntriesTableCreateCompanionBuilder =
    FuelEntriesCompanion Function({
      required String id,
      required String vehicleId,
      required DateTime date,
      required int odometer,
      required Decimal liters,
      required Decimal pricePerLiter,
      required Decimal totalCost,
      required bool fullTank,
      required FuelType fuelType,
      required FuelSource source,
      Value<String?> receiptImageUrl,
      Value<String?> stationName,
      Value<String?> stationBrand,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });
typedef $$FuelEntriesTableUpdateCompanionBuilder =
    FuelEntriesCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<DateTime> date,
      Value<int> odometer,
      Value<Decimal> liters,
      Value<Decimal> pricePerLiter,
      Value<Decimal> totalCost,
      Value<bool> fullTank,
      Value<FuelType> fuelType,
      Value<FuelSource> source,
      Value<String?> receiptImageUrl,
      Value<String?> stationName,
      Value<String?> stationBrand,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$FuelEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FuelEntriesTable> {
  $$FuelEntriesTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get liters =>
      $composableBuilder(
        column: $table.liters,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get pricePerLiter =>
      $composableBuilder(
        column: $table.pricePerLiter,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get totalCost =>
      $composableBuilder(
        column: $table.totalCost,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get fullTank => $composableBuilder(
    column: $table.fullTank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FuelType, FuelType, String> get fuelType =>
      $composableBuilder(
        column: $table.fuelType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<FuelSource, FuelSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationBrand => $composableBuilder(
    column: $table.stationBrand,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$FuelEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FuelEntriesTable> {
  $$FuelEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pricePerLiter => $composableBuilder(
    column: $table.pricePerLiter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fullTank => $composableBuilder(
    column: $table.fullTank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationBrand => $composableBuilder(
    column: $table.stationBrand,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FuelEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FuelEntriesTable> {
  $$FuelEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get odometer =>
      $composableBuilder(column: $table.odometer, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get liters =>
      $composableBuilder(column: $table.liters, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get pricePerLiter =>
      $composableBuilder(
        column: $table.pricePerLiter,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<bool> get fullTank =>
      $composableBuilder(column: $table.fullTank, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FuelType, String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FuelSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stationBrand => $composableBuilder(
    column: $table.stationBrand,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$FuelEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FuelEntriesTable,
          FuelEntryRow,
          $$FuelEntriesTableFilterComposer,
          $$FuelEntriesTableOrderingComposer,
          $$FuelEntriesTableAnnotationComposer,
          $$FuelEntriesTableCreateCompanionBuilder,
          $$FuelEntriesTableUpdateCompanionBuilder,
          (
            FuelEntryRow,
            BaseReferences<_$AppDatabase, $FuelEntriesTable, FuelEntryRow>,
          ),
          FuelEntryRow,
          PrefetchHooks Function()
        > {
  $$FuelEntriesTableTableManager(_$AppDatabase db, $FuelEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FuelEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FuelEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FuelEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> odometer = const Value.absent(),
                Value<Decimal> liters = const Value.absent(),
                Value<Decimal> pricePerLiter = const Value.absent(),
                Value<Decimal> totalCost = const Value.absent(),
                Value<bool> fullTank = const Value.absent(),
                Value<FuelType> fuelType = const Value.absent(),
                Value<FuelSource> source = const Value.absent(),
                Value<String?> receiptImageUrl = const Value.absent(),
                Value<String?> stationName = const Value.absent(),
                Value<String?> stationBrand = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FuelEntriesCompanion(
                id: id,
                vehicleId: vehicleId,
                date: date,
                odometer: odometer,
                liters: liters,
                pricePerLiter: pricePerLiter,
                totalCost: totalCost,
                fullTank: fullTank,
                fuelType: fuelType,
                source: source,
                receiptImageUrl: receiptImageUrl,
                stationName: stationName,
                stationBrand: stationBrand,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                required DateTime date,
                required int odometer,
                required Decimal liters,
                required Decimal pricePerLiter,
                required Decimal totalCost,
                required bool fullTank,
                required FuelType fuelType,
                required FuelSource source,
                Value<String?> receiptImageUrl = const Value.absent(),
                Value<String?> stationName = const Value.absent(),
                Value<String?> stationBrand = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FuelEntriesCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                date: date,
                odometer: odometer,
                liters: liters,
                pricePerLiter: pricePerLiter,
                totalCost: totalCost,
                fullTank: fullTank,
                fuelType: fuelType,
                source: source,
                receiptImageUrl: receiptImageUrl,
                stationName: stationName,
                stationBrand: stationBrand,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FuelEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FuelEntriesTable,
      FuelEntryRow,
      $$FuelEntriesTableFilterComposer,
      $$FuelEntriesTableOrderingComposer,
      $$FuelEntriesTableAnnotationComposer,
      $$FuelEntriesTableCreateCompanionBuilder,
      $$FuelEntriesTableUpdateCompanionBuilder,
      (
        FuelEntryRow,
        BaseReferences<_$AppDatabase, $FuelEntriesTable, FuelEntryRow>,
      ),
      FuelEntryRow,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String id,
      required String vehicleId,
      required DateTime date,
      required ExpenseCategory category,
      required String description,
      required Decimal amount,
      Value<int?> odometer,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<DateTime> date,
      Value<ExpenseCategory> category,
      Value<String> description,
      Value<Decimal> amount,
      Value<int?> odometer,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExpenseCategory, ExpenseCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get amount =>
      $composableBuilder(
        column: $table.amount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get odometer => $composableBuilder(
    column: $table.odometer,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get odometer => $composableBuilder(
    column: $table.odometer,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExpenseCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get odometer =>
      $composableBuilder(column: $table.odometer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          ExpenseRow,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (
            ExpenseRow,
            BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>,
          ),
          ExpenseRow,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<ExpenseCategory> category = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<Decimal> amount = const Value.absent(),
                Value<int?> odometer = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                vehicleId: vehicleId,
                date: date,
                category: category,
                description: description,
                amount: amount,
                odometer: odometer,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                required DateTime date,
                required ExpenseCategory category,
                required String description,
                required Decimal amount,
                Value<int?> odometer = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                date: date,
                category: category,
                description: description,
                amount: amount,
                odometer: odometer,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      ExpenseRow,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (ExpenseRow, BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>),
      ExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      required String vehicleId,
      required ReminderType type,
      required String title,
      Value<int?> dueKm,
      Value<DateTime?> dueDate,
      Value<bool> isDone,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<ReminderType> type,
      Value<String> title,
      Value<int?> dueKm,
      Value<DateTime?> dueDate,
      Value<bool> isDone,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderType, ReminderType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueKm => $composableBuilder(
    column: $table.dueKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueKm => $composableBuilder(
    column: $table.dueKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get dueKm =>
      $composableBuilder(column: $table.dueKm, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (
            ReminderRow,
            BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>,
          ),
          ReminderRow,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<ReminderType> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> dueKm = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                vehicleId: vehicleId,
                type: type,
                title: title,
                dueKm: dueKm,
                dueDate: dueDate,
                isDone: isDone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                required ReminderType type,
                required String title,
                Value<int?> dueKm = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                type: type,
                title: title,
                dueKm: dueKm,
                dueDate: dueDate,
                isDone: isDone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (
        ReminderRow,
        BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>,
      ),
      ReminderRow,
      PrefetchHooks Function()
    >;
typedef $$UsageQuotaTableCreateCompanionBuilder =
    UsageQuotaCompanion Function({
      required String userId,
      required String month,
      Value<int> scanCount,
      Value<bool> isPremium,
      Value<int> rowid,
    });
typedef $$UsageQuotaTableUpdateCompanionBuilder =
    UsageQuotaCompanion Function({
      Value<String> userId,
      Value<String> month,
      Value<int> scanCount,
      Value<bool> isPremium,
      Value<int> rowid,
    });

class $$UsageQuotaTableFilterComposer
    extends Composer<_$AppDatabase, $UsageQuotaTable> {
  $$UsageQuotaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanCount => $composableBuilder(
    column: $table.scanCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPremium => $composableBuilder(
    column: $table.isPremium,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsageQuotaTableOrderingComposer
    extends Composer<_$AppDatabase, $UsageQuotaTable> {
  $$UsageQuotaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanCount => $composableBuilder(
    column: $table.scanCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPremium => $composableBuilder(
    column: $table.isPremium,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsageQuotaTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsageQuotaTable> {
  $$UsageQuotaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get scanCount =>
      $composableBuilder(column: $table.scanCount, builder: (column) => column);

  GeneratedColumn<bool> get isPremium =>
      $composableBuilder(column: $table.isPremium, builder: (column) => column);
}

class $$UsageQuotaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsageQuotaTable,
          UsageQuotaRow,
          $$UsageQuotaTableFilterComposer,
          $$UsageQuotaTableOrderingComposer,
          $$UsageQuotaTableAnnotationComposer,
          $$UsageQuotaTableCreateCompanionBuilder,
          $$UsageQuotaTableUpdateCompanionBuilder,
          (
            UsageQuotaRow,
            BaseReferences<_$AppDatabase, $UsageQuotaTable, UsageQuotaRow>,
          ),
          UsageQuotaRow,
          PrefetchHooks Function()
        > {
  $$UsageQuotaTableTableManager(_$AppDatabase db, $UsageQuotaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageQuotaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageQuotaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageQuotaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<int> scanCount = const Value.absent(),
                Value<bool> isPremium = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsageQuotaCompanion(
                userId: userId,
                month: month,
                scanCount: scanCount,
                isPremium: isPremium,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String month,
                Value<int> scanCount = const Value.absent(),
                Value<bool> isPremium = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsageQuotaCompanion.insert(
                userId: userId,
                month: month,
                scanCount: scanCount,
                isPremium: isPremium,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsageQuotaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsageQuotaTable,
      UsageQuotaRow,
      $$UsageQuotaTableFilterComposer,
      $$UsageQuotaTableOrderingComposer,
      $$UsageQuotaTableAnnotationComposer,
      $$UsageQuotaTableCreateCompanionBuilder,
      $$UsageQuotaTableUpdateCompanionBuilder,
      (
        UsageQuotaRow,
        BaseReferences<_$AppDatabase, $UsageQuotaTable, UsageQuotaRow>,
      ),
      UsageQuotaRow,
      PrefetchHooks Function()
    >;
typedef $$FipeCacheTableCreateCompanionBuilder =
    FipeCacheCompanion Function({
      required String key,
      required String value,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$FipeCacheTableUpdateCompanionBuilder =
    FipeCacheCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$FipeCacheTableFilterComposer
    extends Composer<_$AppDatabase, $FipeCacheTable> {
  $$FipeCacheTableFilterComposer({
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

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FipeCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $FipeCacheTable> {
  $$FipeCacheTableOrderingComposer({
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

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FipeCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $FipeCacheTable> {
  $$FipeCacheTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$FipeCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FipeCacheTable,
          FipeCacheRow,
          $$FipeCacheTableFilterComposer,
          $$FipeCacheTableOrderingComposer,
          $$FipeCacheTableAnnotationComposer,
          $$FipeCacheTableCreateCompanionBuilder,
          $$FipeCacheTableUpdateCompanionBuilder,
          (
            FipeCacheRow,
            BaseReferences<_$AppDatabase, $FipeCacheTable, FipeCacheRow>,
          ),
          FipeCacheRow,
          PrefetchHooks Function()
        > {
  $$FipeCacheTableTableManager(_$AppDatabase db, $FipeCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FipeCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FipeCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FipeCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FipeCacheCompanion(
                key: key,
                value: value,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => FipeCacheCompanion.insert(
                key: key,
                value: value,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FipeCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FipeCacheTable,
      FipeCacheRow,
      $$FipeCacheTableFilterComposer,
      $$FipeCacheTableOrderingComposer,
      $$FipeCacheTableAnnotationComposer,
      $$FipeCacheTableCreateCompanionBuilder,
      $$FipeCacheTableUpdateCompanionBuilder,
      (
        FipeCacheRow,
        BaseReferences<_$AppDatabase, $FipeCacheTable, FipeCacheRow>,
      ),
      FipeCacheRow,
      PrefetchHooks Function()
    >;
typedef $$FipeHistoryTableCreateCompanionBuilder =
    FipeHistoryCompanion Function({
      required String vehicleId,
      required String month,
      required Decimal value,
      required DateTime capturedAt,
      Value<int> rowid,
    });
typedef $$FipeHistoryTableUpdateCompanionBuilder =
    FipeHistoryCompanion Function({
      Value<String> vehicleId,
      Value<String> month,
      Value<Decimal> value,
      Value<DateTime> capturedAt,
      Value<int> rowid,
    });

class $$FipeHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $FipeHistoryTable> {
  $$FipeHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get value =>
      $composableBuilder(
        column: $table.value,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FipeHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $FipeHistoryTable> {
  $$FipeHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FipeHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $FipeHistoryTable> {
  $$FipeHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );
}

class $$FipeHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FipeHistoryTable,
          FipeHistoryRow,
          $$FipeHistoryTableFilterComposer,
          $$FipeHistoryTableOrderingComposer,
          $$FipeHistoryTableAnnotationComposer,
          $$FipeHistoryTableCreateCompanionBuilder,
          $$FipeHistoryTableUpdateCompanionBuilder,
          (
            FipeHistoryRow,
            BaseReferences<_$AppDatabase, $FipeHistoryTable, FipeHistoryRow>,
          ),
          FipeHistoryRow,
          PrefetchHooks Function()
        > {
  $$FipeHistoryTableTableManager(_$AppDatabase db, $FipeHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FipeHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FipeHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FipeHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> vehicleId = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<Decimal> value = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FipeHistoryCompanion(
                vehicleId: vehicleId,
                month: month,
                value: value,
                capturedAt: capturedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String vehicleId,
                required String month,
                required Decimal value,
                required DateTime capturedAt,
                Value<int> rowid = const Value.absent(),
              }) => FipeHistoryCompanion.insert(
                vehicleId: vehicleId,
                month: month,
                value: value,
                capturedAt: capturedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FipeHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FipeHistoryTable,
      FipeHistoryRow,
      $$FipeHistoryTableFilterComposer,
      $$FipeHistoryTableOrderingComposer,
      $$FipeHistoryTableAnnotationComposer,
      $$FipeHistoryTableCreateCompanionBuilder,
      $$FipeHistoryTableUpdateCompanionBuilder,
      (
        FipeHistoryRow,
        BaseReferences<_$AppDatabase, $FipeHistoryTable, FipeHistoryRow>,
      ),
      FipeHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$UserProfileTableCreateCompanionBuilder =
    UserProfileCompanion Function({
      required String userId,
      Value<String?> cnhNumber,
      Value<String?> cnhCategory,
      Value<DateTime?> cnhExpiresAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<String> userId,
      Value<String?> cnhNumber,
      Value<String?> cnhCategory,
      Value<DateTime?> cnhExpiresAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cnhNumber => $composableBuilder(
    column: $table.cnhNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cnhCategory => $composableBuilder(
    column: $table.cnhCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cnhExpiresAt => $composableBuilder(
    column: $table.cnhExpiresAt,
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

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cnhNumber => $composableBuilder(
    column: $table.cnhNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cnhCategory => $composableBuilder(
    column: $table.cnhCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cnhExpiresAt => $composableBuilder(
    column: $table.cnhExpiresAt,
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

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get cnhNumber =>
      $composableBuilder(column: $table.cnhNumber, builder: (column) => column);

  GeneratedColumn<String> get cnhCategory => $composableBuilder(
    column: $table.cnhCategory,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cnhExpiresAt => $composableBuilder(
    column: $table.cnhExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$UserProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTable,
          UserProfileRow,
          $$UserProfileTableFilterComposer,
          $$UserProfileTableOrderingComposer,
          $$UserProfileTableAnnotationComposer,
          $$UserProfileTableCreateCompanionBuilder,
          $$UserProfileTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileRow>,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> cnhNumber = const Value.absent(),
                Value<String?> cnhCategory = const Value.absent(),
                Value<DateTime?> cnhExpiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion(
                userId: userId,
                cnhNumber: cnhNumber,
                cnhCategory: cnhCategory,
                cnhExpiresAt: cnhExpiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> cnhNumber = const Value.absent(),
                Value<String?> cnhCategory = const Value.absent(),
                Value<DateTime?> cnhExpiresAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion.insert(
                userId: userId,
                cnhNumber: cnhNumber,
                cnhCategory: cnhCategory,
                cnhExpiresAt: cnhExpiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTable,
      UserProfileRow,
      $$UserProfileTableFilterComposer,
      $$UserProfileTableOrderingComposer,
      $$UserProfileTableAnnotationComposer,
      $$UserProfileTableCreateCompanionBuilder,
      $$UserProfileTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;
typedef $$FinesTableCreateCompanionBuilder =
    FinesCompanion Function({
      required String id,
      required String vehicleId,
      Value<String?> autoNumber,
      required DateTime issuedAt,
      required String description,
      required Decimal amount,
      Value<DateTime?> dueDate,
      Value<bool> paid,
      Value<int?> points,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });
typedef $$FinesTableUpdateCompanionBuilder =
    FinesCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<String?> autoNumber,
      Value<DateTime> issuedAt,
      Value<String> description,
      Value<Decimal> amount,
      Value<DateTime?> dueDate,
      Value<bool> paid,
      Value<int?> points,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$FinesTableFilterComposer extends Composer<_$AppDatabase, $FinesTable> {
  $$FinesTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get autoNumber => $composableBuilder(
    column: $table.autoNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get amount =>
      $composableBuilder(
        column: $table.amount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paid => $composableBuilder(
    column: $table.paid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$FinesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinesTable> {
  $$FinesTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get autoNumber => $composableBuilder(
    column: $table.autoNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paid => $composableBuilder(
    column: $table.paid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinesTable> {
  $$FinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get autoNumber => $composableBuilder(
    column: $table.autoNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get paid =>
      $composableBuilder(column: $table.paid, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$FinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinesTable,
          FineRow,
          $$FinesTableFilterComposer,
          $$FinesTableOrderingComposer,
          $$FinesTableAnnotationComposer,
          $$FinesTableCreateCompanionBuilder,
          $$FinesTableUpdateCompanionBuilder,
          (FineRow, BaseReferences<_$AppDatabase, $FinesTable, FineRow>),
          FineRow,
          PrefetchHooks Function()
        > {
  $$FinesTableTableManager(_$AppDatabase db, $FinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String?> autoNumber = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<Decimal> amount = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> paid = const Value.absent(),
                Value<int?> points = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinesCompanion(
                id: id,
                vehicleId: vehicleId,
                autoNumber: autoNumber,
                issuedAt: issuedAt,
                description: description,
                amount: amount,
                dueDate: dueDate,
                paid: paid,
                points: points,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                Value<String?> autoNumber = const Value.absent(),
                required DateTime issuedAt,
                required String description,
                required Decimal amount,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> paid = const Value.absent(),
                Value<int?> points = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinesCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                autoNumber: autoNumber,
                issuedAt: issuedAt,
                description: description,
                amount: amount,
                dueDate: dueDate,
                paid: paid,
                points: points,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinesTable,
      FineRow,
      $$FinesTableFilterComposer,
      $$FinesTableOrderingComposer,
      $$FinesTableAnnotationComposer,
      $$FinesTableCreateCompanionBuilder,
      $$FinesTableUpdateCompanionBuilder,
      (FineRow, BaseReferences<_$AppDatabase, $FinesTable, FineRow>),
      FineRow,
      PrefetchHooks Function()
    >;
typedef $$InsurancesTableCreateCompanionBuilder =
    InsurancesCompanion Function({
      required String id,
      required String vehicleId,
      Value<String?> insurer,
      Value<String?> policyNumber,
      required DateTime startsAt,
      required DateTime endsAt,
      Value<Decimal?> premiumPaid,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });
typedef $$InsurancesTableUpdateCompanionBuilder =
    InsurancesCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<String?> insurer,
      Value<String?> policyNumber,
      Value<DateTime> startsAt,
      Value<DateTime> endsAt,
      Value<Decimal?> premiumPaid,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$InsurancesTableFilterComposer
    extends Composer<_$AppDatabase, $InsurancesTable> {
  $$InsurancesTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get insurer => $composableBuilder(
    column: $table.insurer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get policyNumber => $composableBuilder(
    column: $table.policyNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get premiumPaid =>
      $composableBuilder(
        column: $table.premiumPaid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$InsurancesTableOrderingComposer
    extends Composer<_$AppDatabase, $InsurancesTable> {
  $$InsurancesTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get insurer => $composableBuilder(
    column: $table.insurer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get policyNumber => $composableBuilder(
    column: $table.policyNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get premiumPaid => $composableBuilder(
    column: $table.premiumPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InsurancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InsurancesTable> {
  $$InsurancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get insurer =>
      $composableBuilder(column: $table.insurer, builder: (column) => column);

  GeneratedColumn<String> get policyNumber => $composableBuilder(
    column: $table.policyNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal?, String> get premiumPaid =>
      $composableBuilder(
        column: $table.premiumPaid,
        builder: (column) => column,
      );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$InsurancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InsurancesTable,
          InsuranceRow,
          $$InsurancesTableFilterComposer,
          $$InsurancesTableOrderingComposer,
          $$InsurancesTableAnnotationComposer,
          $$InsurancesTableCreateCompanionBuilder,
          $$InsurancesTableUpdateCompanionBuilder,
          (
            InsuranceRow,
            BaseReferences<_$AppDatabase, $InsurancesTable, InsuranceRow>,
          ),
          InsuranceRow,
          PrefetchHooks Function()
        > {
  $$InsurancesTableTableManager(_$AppDatabase db, $InsurancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InsurancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InsurancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InsurancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String?> insurer = const Value.absent(),
                Value<String?> policyNumber = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<DateTime> endsAt = const Value.absent(),
                Value<Decimal?> premiumPaid = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InsurancesCompanion(
                id: id,
                vehicleId: vehicleId,
                insurer: insurer,
                policyNumber: policyNumber,
                startsAt: startsAt,
                endsAt: endsAt,
                premiumPaid: premiumPaid,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                Value<String?> insurer = const Value.absent(),
                Value<String?> policyNumber = const Value.absent(),
                required DateTime startsAt,
                required DateTime endsAt,
                Value<Decimal?> premiumPaid = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InsurancesCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                insurer: insurer,
                policyNumber: policyNumber,
                startsAt: startsAt,
                endsAt: endsAt,
                premiumPaid: premiumPaid,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InsurancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InsurancesTable,
      InsuranceRow,
      $$InsurancesTableFilterComposer,
      $$InsurancesTableOrderingComposer,
      $$InsurancesTableAnnotationComposer,
      $$InsurancesTableCreateCompanionBuilder,
      $$InsurancesTableUpdateCompanionBuilder,
      (
        InsuranceRow,
        BaseReferences<_$AppDatabase, $InsurancesTable, InsuranceRow>,
      ),
      InsuranceRow,
      PrefetchHooks Function()
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      required String id,
      required String vehicleId,
      required String role,
      required String content,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<String> role,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessageRow,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (
            ChatMessageRow,
            BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow>,
          ),
          ChatMessageRow,
          PrefetchHooks Function()
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                vehicleId: vehicleId,
                role: role,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                required String role,
                required String content,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                role: role,
                content: content,
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

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessageRow,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (
        ChatMessageRow,
        BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow>,
      ),
      ChatMessageRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationsLogTableCreateCompanionBuilder =
    NotificationsLogCompanion Function({
      required String id,
      required String vehicleId,
      required String category,
      required DateTime sentAt,
      required String title,
      required String body,
      Value<int> rowid,
    });
typedef $$NotificationsLogTableUpdateCompanionBuilder =
    NotificationsLogCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<String> category,
      Value<DateTime> sentAt,
      Value<String> title,
      Value<String> body,
      Value<int> rowid,
    });

class $$NotificationsLogTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsLogTable> {
  $$NotificationsLogTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsLogTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsLogTable> {
  $$NotificationsLogTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsLogTable> {
  $$NotificationsLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$NotificationsLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsLogTable,
          NotificationLogRow,
          $$NotificationsLogTableFilterComposer,
          $$NotificationsLogTableOrderingComposer,
          $$NotificationsLogTableAnnotationComposer,
          $$NotificationsLogTableCreateCompanionBuilder,
          $$NotificationsLogTableUpdateCompanionBuilder,
          (
            NotificationLogRow,
            BaseReferences<
              _$AppDatabase,
              $NotificationsLogTable,
              NotificationLogRow
            >,
          ),
          NotificationLogRow,
          PrefetchHooks Function()
        > {
  $$NotificationsLogTableTableManager(
    _$AppDatabase db,
    $NotificationsLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsLogCompanion(
                id: id,
                vehicleId: vehicleId,
                category: category,
                sentAt: sentAt,
                title: title,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                required String category,
                required DateTime sentAt,
                required String title,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => NotificationsLogCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                category: category,
                sentAt: sentAt,
                title: title,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsLogTable,
      NotificationLogRow,
      $$NotificationsLogTableFilterComposer,
      $$NotificationsLogTableOrderingComposer,
      $$NotificationsLogTableAnnotationComposer,
      $$NotificationsLogTableCreateCompanionBuilder,
      $$NotificationsLogTableUpdateCompanionBuilder,
      (
        NotificationLogRow,
        BaseReferences<
          _$AppDatabase,
          $NotificationsLogTable,
          NotificationLogRow
        >,
      ),
      NotificationLogRow,
      PrefetchHooks Function()
    >;
typedef $$FiscalLookupCacheTableCreateCompanionBuilder =
    FiscalLookupCacheCompanion Function({
      required String cacheKey,
      required String value,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$FiscalLookupCacheTableUpdateCompanionBuilder =
    FiscalLookupCacheCompanion Function({
      Value<String> cacheKey,
      Value<String> value,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$FiscalLookupCacheTableFilterComposer
    extends Composer<_$AppDatabase, $FiscalLookupCacheTable> {
  $$FiscalLookupCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FiscalLookupCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $FiscalLookupCacheTable> {
  $$FiscalLookupCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FiscalLookupCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $FiscalLookupCacheTable> {
  $$FiscalLookupCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$FiscalLookupCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FiscalLookupCacheTable,
          FiscalLookupCacheRow,
          $$FiscalLookupCacheTableFilterComposer,
          $$FiscalLookupCacheTableOrderingComposer,
          $$FiscalLookupCacheTableAnnotationComposer,
          $$FiscalLookupCacheTableCreateCompanionBuilder,
          $$FiscalLookupCacheTableUpdateCompanionBuilder,
          (
            FiscalLookupCacheRow,
            BaseReferences<
              _$AppDatabase,
              $FiscalLookupCacheTable,
              FiscalLookupCacheRow
            >,
          ),
          FiscalLookupCacheRow,
          PrefetchHooks Function()
        > {
  $$FiscalLookupCacheTableTableManager(
    _$AppDatabase db,
    $FiscalLookupCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiscalLookupCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiscalLookupCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiscalLookupCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FiscalLookupCacheCompanion(
                cacheKey: cacheKey,
                value: value,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String value,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => FiscalLookupCacheCompanion.insert(
                cacheKey: cacheKey,
                value: value,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FiscalLookupCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FiscalLookupCacheTable,
      FiscalLookupCacheRow,
      $$FiscalLookupCacheTableFilterComposer,
      $$FiscalLookupCacheTableOrderingComposer,
      $$FiscalLookupCacheTableAnnotationComposer,
      $$FiscalLookupCacheTableCreateCompanionBuilder,
      $$FiscalLookupCacheTableUpdateCompanionBuilder,
      (
        FiscalLookupCacheRow,
        BaseReferences<
          _$AppDatabase,
          $FiscalLookupCacheTable,
          FiscalLookupCacheRow
        >,
      ),
      FiscalLookupCacheRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$FuelEntriesTableTableManager get fuelEntries =>
      $$FuelEntriesTableTableManager(_db, _db.fuelEntries);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$UsageQuotaTableTableManager get usageQuota =>
      $$UsageQuotaTableTableManager(_db, _db.usageQuota);
  $$FipeCacheTableTableManager get fipeCache =>
      $$FipeCacheTableTableManager(_db, _db.fipeCache);
  $$FipeHistoryTableTableManager get fipeHistory =>
      $$FipeHistoryTableTableManager(_db, _db.fipeHistory);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$FinesTableTableManager get fines =>
      $$FinesTableTableManager(_db, _db.fines);
  $$InsurancesTableTableManager get insurances =>
      $$InsurancesTableTableManager(_db, _db.insurances);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$NotificationsLogTableTableManager get notificationsLog =>
      $$NotificationsLogTableTableManager(_db, _db.notificationsLog);
  $$FiscalLookupCacheTableTableManager get fiscalLookupCache =>
      $$FiscalLookupCacheTableTableManager(_db, _db.fiscalLookupCache);
}
