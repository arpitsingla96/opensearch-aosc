/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * The OpenSearch Contributors require contributions made to
 * this file be licensed under the Apache-2.0 license or a
 * compatible open source license.
 */
package com.atlassian.opensearch.aosc.compat;

import org.apache.hc.core5.http.ContentType;
import org.apache.hc.core5.http.ParseException;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.apache.hc.core5.http.io.entity.StringEntity;

import org.opensearch.client.Response;

import java.io.IOException;

public final class HttpCompat {

    private HttpCompat() {}

    public static StringEntity jsonEntity(String json) {
        return new StringEntity(json, ContentType.APPLICATION_JSON);
    }

    public static String responseBody(Response response) throws IOException {
        try {
            return EntityUtils.toString(response.getEntity());
        } catch (ParseException e) {
            throw new IOException(e);
        }
    }
}
