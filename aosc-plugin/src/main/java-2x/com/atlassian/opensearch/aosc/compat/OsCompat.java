/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * The OpenSearch Contributors require contributions made to
 * this file be licensed under the Apache-2.0 license or a
 * compatible open source license.
 */
package com.atlassian.opensearch.aosc.compat;

import org.apache.lucene.index.IndexReader;
import org.apache.lucene.index.StoredFieldVisitor;
import org.apache.lucene.search.TotalHits;

import java.io.IOException;

public final class OsCompat {

    private OsCompat() {}

    public static long totalHitCount(TotalHits totalHits) {
        return totalHits.value;
    }

    public static void readStoredFields(IndexReader reader, int docId, StoredFieldVisitor visitor) throws IOException {
        reader.document(docId, visitor);
    }
}
