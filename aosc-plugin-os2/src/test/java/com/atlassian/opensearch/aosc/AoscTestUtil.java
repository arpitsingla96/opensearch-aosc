/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * The OpenSearch Contributors require contributions made to
 * this file be licensed under the Apache-2.0 license or a
 * compatible open source license.
 */
package com.atlassian.opensearch.aosc;

import com.atlassian.opensearch.aosc.model.MigrationRequestOptions;

/** Shared test helpers for AOSC unit tests. */
public final class AoscTestUtil {
    /** Returns a fully-populated {@link MigrationRequestOptions} with sensible defaults for tests. */
    public static MigrationRequestOptions defaultMigrationOptions() {
        return new MigrationRequestOptions().setConvergenceThresholdPerShard(AoscSettings.CONVERGENCE_THRESHOLD_DEFAULT)
            .setMaxConvergenceRoundsPerShard(AoscSettings.MAX_CONVERGENCE_ROUNDS_DEFAULT)
            .setDocCountTolerance(0)
            .setAcceptDataLossIfCustomRoutingIsUsed(false)
            .setTransientTargetSettings(AoscSettings.parseTransientTargetSettings(AoscSettings.TRANSIENT_TARGET_SETTINGS_DEFAULT));
    }

    private AoscTestUtil() {}
}
