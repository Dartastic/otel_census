// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_census/otel_census.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_census-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('syncs.trigger records source + dest + record breakdown', () async {
    await tracedCensus<String>(
      operation: 'syncs.trigger',
      invoke: () async => const CensusCallResult(
        value: 'ok',
        result: CensusResult(
          workspaceId: 'ws_1',
          sourceConnection: 'snowflake',
          modelId: 'm_1',
          syncId: 'sync_1',
          destinationConnection: 'salesforce',
          objectName: 'Contact',
          syncRunId: 'run_1',
          behavior: 'upsert',
          runStatus: 'success',
          recordsProcessed: 1000000,
          recordsUpdated: 4500,
          recordsInvalid: 2,
          recordsFailed: 1,
          scheduleType: 'dbt_cloud',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('census syncs.trigger')!);
    expect(a['census.source.connection'], 'snowflake');
    expect(a['census.destination.connection'], 'salesforce');
    expect(a['census.destination.object'], 'Contact');
    expect(a['census.behavior'], 'upsert');
    expect(a['census.records.updated'], 4500);
    expect(a['census.schedule.type'], 'dbt_cloud');
  });

  test('failed run sets span error', () async {
    await tracedCensus<String>(
      operation: 'sync_runs.get',
      invoke: () async => const CensusCallResult(
        value: 'ok',
        result: CensusResult(
          runStatus: 'failed',
          recordsProcessed: 1000,
          recordsUpdated: 0,
        ),
      ),
    );
    expect(
      spans.findSpanByName('census sync_runs.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('warning does NOT set span error', () async {
    await tracedCensus<String>(
      operation: 'sync_runs.get',
      invoke: () async => const CensusCallResult(
        value: 'ok',
        result: CensusResult(
          runStatus: 'warning',
          recordsInvalid: 5,
        ),
      ),
    );
    expect(
      spans.findSpanByName('census sync_runs.get')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutCensusInstrumentationAsync(() async {
      await tracedCensus<String>(
        operation: 'syncs.list',
        invoke: () async => const CensusCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('census '), isEmpty);
  });
}
