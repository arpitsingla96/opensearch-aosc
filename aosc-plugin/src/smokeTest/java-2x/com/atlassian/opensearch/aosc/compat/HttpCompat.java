/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * The OpenSearch Contributors require contributions made to
 * this file be licensed under the Apache-2.0 license or a
 * compatible open source license.
 */
package com.atlassian.opensearch.aosc.compat;

import org.apache.http.entity.ContentType;
import org.apache.http.entity.StringEntity;
import org.apache.http.util.EntityUtils;

import org.opensearch.client.Response;

import java.io.IOException;

public final class HttpCompat {

    private HttpCompat() {}

    public static StringEntity jsonEntity(String json) {
        return new StringEntity(json, ContentType.APPLICATION_JSON);
    }

    public static String responseBody(Response response) throws IOException {
        return EntityUtils.toString(response.getEntity());
    }
}
