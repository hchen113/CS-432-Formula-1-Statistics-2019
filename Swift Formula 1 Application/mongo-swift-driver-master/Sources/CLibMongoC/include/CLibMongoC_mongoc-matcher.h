/*
 * Copyright 2014 MongoDB, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "CLibMongoC_mongoc-prelude.h"

#ifndef MONGOC_MATCHER_H
#define MONGOC_MATCHER_H

#include "CLibMongoC_bson.h"

#include "CLibMongoC_mongoc-macros.h"

BSON_BEGIN_DECLS


typedef struct _mongoc_matcher_t mongoc_matcher_t;


MONGOC_EXPORT (mongoc_matcher_t *)
mongoc_matcher_new (const bson_t *query,
                    bson_error_t *error) BSON_GNUC_DEPRECATED;
MONGOC_EXPORT (bool)
mongoc_matcher_match (const mongoc_matcher_t *matcher,
                      const bson_t *document) BSON_GNUC_DEPRECATED;
MONGOC_EXPORT (void)
mongoc_matcher_destroy (mongoc_matcher_t *matcher) BSON_GNUC_DEPRECATED;


BSON_END_DECLS


#endif /* MONGOC_MATCHER_H */
