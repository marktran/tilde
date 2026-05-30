#!/usr/bin/env node

import { createHash } from 'node:crypto';

import {
  buildR6ReleaseParityEvalResultV0,
  runRecordedR6ReleaseParityProofV0,
} from '@openprose/reactor-cradle/release-parity';
import {
  projectCradleEvalResultV0,
  renderCradleEvalProjectionReportMarkdownV0,
  renderCradleEvalReportMarkdownV0,
} from '@openprose/reactor-cradle/eval';
import { inspectReceiptProofV0 } from '@openprose/reactor/receipt';
import { projectReceiptProofV0 } from '@openprose/reactor/projection';

const EXAMPLE_SCHEMA = 'openprose.reactor.example.release-readiness';
const EXAMPLE_VERSION = 0;
const EXAMPLE_ID = 'reactor-release-readiness';

const proof = runRecordedR6ReleaseParityProofV0();
const evalResult = buildR6ReleaseParityEvalResultV0(proof);
const publicProjection = projectCradleEvalResultV0(evalResult, 'public');
const evalReport = renderCradleEvalReportMarkdownV0(evalResult);
const projectionReport =
  renderCradleEvalProjectionReportMarkdownV0(publicProjection);

const sampledReceipt = firstReceipt(proof);
const receiptProof = inspectReceiptProofV0(sampledReceipt);
if (!receiptProof.ok) {
  throw new Error(`sampled receipt proof failed: ${receiptProof.errors.join('; ')}`);
}

const sampledReceiptProjection = projectReceiptProofV0({
  proof: receiptProof,
  tier: 'public',
});
if (!sampledReceiptProjection.ok) {
  throw new Error(
    `sampled receipt projection failed: ${sampledReceiptProjection.errors.join('; ')}`,
  );
}

const output = {
  schema: EXAMPLE_SCHEMA,
  v: EXAMPLE_VERSION,
  example_id: EXAMPLE_ID,
  package_imports: [
    '@openprose/reactor-cradle/release-parity',
    '@openprose/reactor-cradle/eval',
    '@openprose/reactor/receipt',
    '@openprose/reactor/projection',
  ],
  release_parity: {
    suite_id: evalResult.suite_id,
    eval_content_hash: evalResult.content_hash,
    public_projection_content_hash: publicProjection.content_hash,
    public_projection_source_hash: publicProjection.source_content_hash,
  },
  overall_status: evalResult.overall_status,
  metrics: {
    case_count: evalResult.metrics.case_count,
    case_pass_count: evalResult.metrics.case_pass_count,
    assertion_count: evalResult.metrics.assertion_count,
    assertion_pass_count: evalResult.metrics.assertion_pass_count,
    replay_parity_ready_rows_run:
      evalResult.metrics.replay_parity_ready_rows_run,
    replay_parity_future_rows: evalResult.metrics.replay_parity_future_rows,
  },
  model_matrix_status: evalResult.model_matrix.status,
  sampled_receipt: {
    content_hash: sampledReceipt.content_hash,
    proof_ok: receiptProof.ok,
    public_projection_tier: sampledReceiptProjection.projection.tier,
    public_projection_content_hash:
      sampledReceiptProjection.projection.content_hash,
  },
  deferred_rows: proof.suite.deferred_cases.map((item) => ({
    row_id: item.case_id,
    represented: false,
  })),
  reports: {
    eval_markdown_sha256: sha256(evalReport),
    eval_markdown_bytes: Buffer.byteLength(evalReport, 'utf8'),
    projection_markdown_sha256: sha256(projectionReport),
    projection_markdown_bytes: Buffer.byteLength(projectionReport, 'utf8'),
  },
};

process.stdout.write(`${JSON.stringify(output, null, 2)}\n`);

function firstReceipt(releaseParityProof) {
  for (const item of releaseParityProof.suite.cases) {
    const receipt = item.receipts[0];
    if (receipt !== undefined) {
      return receipt;
    }
  }

  throw new Error('release parity proof did not include any receipts');
}

function sha256(text) {
  return `sha256:${createHash('sha256').update(text, 'utf8').digest('hex')}`;
}
