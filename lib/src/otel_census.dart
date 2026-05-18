// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_census_suppression.dart';

const _tracerName = 'dartastic_otel_libs_census';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class CensusResult {
  const CensusResult({
    this.workspaceId,
    this.sourceConnection,
    this.modelId,
    this.segmentId,
    this.syncId,
    this.destinationConnection,
    this.objectName,
    this.syncRunId,
    this.behavior,
    this.runStatus,
    this.recordsProcessed,
    this.recordsUpdated,
    this.recordsInvalid,
    this.recordsFailed,
    this.scheduleType,
    this.statusCode,
  });

  /// Census workspace (tenant).
  final String? workspaceId;

  /// `snowflake` / `bigquery` / `databricks` / `redshift` / `postgres`
  /// / `mongodb` / `mysql` — warehouse connection key.
  final String? sourceConnection;

  final String? modelId;

  /// Segment id (Census's audience-builder layer over a model).
  final String? segmentId;

  final String? syncId;

  /// `salesforce` / `hubspot` / `marketo` / `intercom` / `iterable` /
  /// `customer_io` / `mixpanel` / `amplitude` / `klaviyo` / `airtable`
  /// / `gsheets` / `slack` / `webhook` / `mysql` / `postgres` /
  /// `bigquery`.
  final String? destinationConnection;

  /// Salesforce Object / HubSpot Contact / Marketo Lead / Mixpanel
  /// User Event / etc — the destination entity Census writes to.
  final String? objectName;

  final String? syncRunId;

  /// `upsert` / `update_only` / `insert_only` / `delete` / `mirror`.
  final String? behavior;

  /// `running` / `success` / `failed` / `warning` / `cancelled` /
  /// `working` / `triggered`.
  final String? runStatus;

  /// Source records the model returned.
  final int? recordsProcessed;

  /// Rows actually pushed to destination after diffing.
  final int? recordsUpdated;

  /// Validation rejects (e.g., destination field constraints).
  final int? recordsInvalid;

  /// Destination accepted-but-failed (rate limit, validation, etc.).
  final int? recordsFailed;

  /// `manual` / `schedule` / `dbt_cloud` / `cron` / `continuous` /
  /// `webhook`.
  final String? scheduleType;

  final int? statusCode;
}

class CensusCallResult<T> {
  const CensusCallResult({required this.value, this.result});
  final T value;
  final CensusResult? result;
}

/// Wraps a Census API call in a CLIENT span. [operation] is one of
/// `syncs.list`, `syncs.get`, `syncs.create`, `syncs.trigger`,
/// `sync_runs.list`, `sync_runs.get`, `models.list`, `models.create`,
/// `segments.list`, `segments.create`, `destinations.list`,
/// `sources.list`, `datasets.list`.
Future<T> tracedCensus<T>({
  required String operation,
  required Future<CensusCallResult<T>> Function() invoke,
}) async {
  if (censusInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'census',
    'rpc.method': operation,
    'census.operation': operation,
  };

  final span = _tracer().startSpan(
    'census $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.workspaceId != null) {
        extras.add(OTel.attributeString(
          'census.workspace.id',
          r.result!.workspaceId!,
        ));
      }
      if (r.result!.sourceConnection != null) {
        extras.add(OTel.attributeString(
          'census.source.connection',
          r.result!.sourceConnection!,
        ));
      }
      if (r.result!.modelId != null) {
        extras.add(OTel.attributeString(
          'census.model.id',
          r.result!.modelId!,
        ));
      }
      if (r.result!.segmentId != null) {
        extras.add(OTel.attributeString(
          'census.segment.id',
          r.result!.segmentId!,
        ));
      }
      if (r.result!.syncId != null) {
        extras.add(OTel.attributeString(
          'census.sync.id',
          r.result!.syncId!,
        ));
      }
      if (r.result!.destinationConnection != null) {
        extras.add(OTel.attributeString(
          'census.destination.connection',
          r.result!.destinationConnection!,
        ));
      }
      if (r.result!.objectName != null) {
        extras.add(OTel.attributeString(
          'census.destination.object',
          r.result!.objectName!,
        ));
      }
      if (r.result!.syncRunId != null) {
        extras.add(OTel.attributeString(
          'census.sync_run.id',
          r.result!.syncRunId!,
        ));
      }
      if (r.result!.behavior != null) {
        extras.add(OTel.attributeString(
          'census.behavior',
          r.result!.behavior!,
        ));
      }
      if (r.result!.runStatus != null) {
        extras.add(OTel.attributeString(
          'census.run.status',
          r.result!.runStatus!,
        ));
        if (r.result!.runStatus == 'failed') {
          span.setStatus(SpanStatusCode.Error, 'Census run failed');
        }
      }
      if (r.result!.recordsProcessed != null) {
        extras.add(OTel.attributeInt(
          'census.records.processed',
          r.result!.recordsProcessed!,
        ));
      }
      if (r.result!.recordsUpdated != null) {
        extras.add(OTel.attributeInt(
          'census.records.updated',
          r.result!.recordsUpdated!,
        ));
      }
      if (r.result!.recordsInvalid != null) {
        extras.add(OTel.attributeInt(
          'census.records.invalid',
          r.result!.recordsInvalid!,
        ));
      }
      if (r.result!.recordsFailed != null) {
        extras.add(OTel.attributeInt(
          'census.records.failed',
          r.result!.recordsFailed!,
        ));
      }
      if (r.result!.scheduleType != null) {
        extras.add(OTel.attributeString(
          'census.schedule.type',
          r.result!.scheduleType!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Census HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
