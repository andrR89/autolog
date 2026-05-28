import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_member.freezed.dart';
part 'vehicle_member.g.dart';

/// Representa um membro compartilhado de um veículo.
///
/// role: 'owner' (criador) ou 'member' (acesso total, igual ao owner no MVP).
/// Sem soft delete — remoção é DELETE direto.
@freezed
abstract class VehicleMember with _$VehicleMember {
  const factory VehicleMember({
    required String vehicleId,
    required String userId,
    required String role,
    required DateTime createdAt,
  }) = _VehicleMember;

  factory VehicleMember.fromJson(Map<String, dynamic> json) =>
      _$VehicleMemberFromJson(json);
}
