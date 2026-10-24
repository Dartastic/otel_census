// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_census/otel_census.dart';

/// Traces Census calls with OpenTelemetry.
///
/// `otel_census` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Census call in
/// [tracedCensus]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'census-example');

  // Wraps a Census API call in a CLIENT span.
  final censusId = await tracedCensus<String>(
    operation: 'syncs.create',
    invoke: () async {
      // Make the Census call here, then report what it returned.
      const id = 'census_8f3a2c';
      return const CensusCallResult(
          value: id,
          result: CensusResult(
              workspaceId: 'workspace_8f3a2c',
              sourceConnection: 'snowflake',
              modelId: 'model_8f3a2c',
              segmentId: 'segment_8f3a2c',
              syncId: 'sync_8f3a2c',
              destinationConnection: 'salesforce',
              objectName: 'example',
              syncRunId: 'syncrun_8f3a2c',
              behavior: 'upsert',
              runStatus: 'running',
              recordsProcessed: 1,
              recordsUpdated: 1,
              recordsInvalid: 1,
              recordsFailed: 1,
              scheduleType: 'manual',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedCensus syncs.create returned $censusId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCensusInstrumentationAsync.
  await runWithoutCensusInstrumentationAsync(
    () => tracedCensus<String>(
      operation: 'syncs.create',
      invoke: () async {
        const id = 'census_8f3a2c';
        return const CensusCallResult(
            value: id,
            result: CensusResult(
                workspaceId: 'workspace_8f3a2c',
                sourceConnection: 'snowflake',
                modelId: 'model_8f3a2c',
                segmentId: 'segment_8f3a2c',
                syncId: 'sync_8f3a2c',
                destinationConnection: 'salesforce',
                objectName: 'example',
                syncRunId: 'syncrun_8f3a2c',
                behavior: 'upsert',
                runStatus: 'running',
                recordsProcessed: 1,
                recordsUpdated: 1,
                recordsInvalid: 1,
                recordsFailed: 1,
                scheduleType: 'manual',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
