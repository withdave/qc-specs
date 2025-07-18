# qc-specs

This repo pulls published REST specifications for Qlik Cloud from [Qlik Developer](https://qlik.dev) each night and syncs to a Postman collection at [Qlik Cloud APIs](https://www.postman.com/qlik-api/api-reference/overview).

## Contents

### `specs/` Folder
Individual API specification files for published Qlik Cloud services.

### `consolidated/` Folder
- `qlik-cloud.json` - Complete OpenAPI specification combining all APIs into a single file.

## Using in Postman

If you wish to be able to sync to the latest release, fork the sync'd collection from [Qlik Cloud APIs](https://www.postman.com/qlik-api/api-reference/overview).

To import manually:

1. **Download** the consolidated specification: `consolidated/qlik-cloud.json`
2. **Open Postman** and click "Import"
3. **Select** the downloaded `qlik-cloud.json` file
4. **Import** - Postman will create a new collection with all Qlik Cloud APIs

## Authentication Options

To make your credentials more secure, and to keep them portable, it's recommended
to use environments to store them. Both options below are supported for the `/api`
path in the collection, while the `/login` and `/oauth` paths require different
patterns.

### API Key Authentication

For simple integration and testing where you want to call endpoints with the permissions
of your interactive user:

1. Generate an API key at https://qlik.dev/authenticate/api-key/generate-your-first-api-key/
2. In Postman, set the authentication type to "Bearer Token"
3. Create an environment in Postman:
  - `baseUrl`: The tenant URL, in format `https://tenantname.region.qlikcloud.com`
  - `apiKey`: The API key for your user
4. Update the `Authorization` configuration for the `/api` path to `Bearer Token`, and set
   the value of `Token` to `{{apiKey}}`.

### OAuth2 Machine-to-Machine Authentication

For production applications and automated systems, or where you want fine grain control
of scopes and permissions:

1. Create an OAuth2 client at https://qlik.dev/authenticate/oauth/create/create-oauth2-client
2. Configure the client with appropriate scopes
3. Create an environment in Postman:
  - `baseUrl`: The tenant URL, in format `https://tenantname.region.qlikcloud.com`
  - `clientId`: The client ID for the Qlik Cloud OAuth M2M client
  - `clientSecret`: The client secret for the Qlik Cloud OAuth M2M client
4. Update the `Authorization` configuration for the `/api` path to `OAuth 2.0`, with:
  - `Add auth data to` set to `Request Headers` (default)
  - `Header Prefix` set to `Bearer` (default)
  - `Token Name` set to a string that explains to you what the token is for (e.g. `Qlik Cloud`)
  - `Grant type` set to `client_credentials` (default)
  - `Access Token URL` set to `{{baseUrl}}/oauth/token`
  - `Client ID` set to `{{clientId}}`
  - `Client Secret` set to `{{clientSecret}}`
  - `Scope` set to match hat you configured in 2, e.g. `user_default admin_classic`
  - `Client Authentication` set to `Send client credentials in body`
5. Click `Get New Access Token`, and follow the prompt
6. Ensure `Auto-refresh Token` is toggled to on

## Usage

The consolidated OpenAPI specification can be used with:

- **Postman** (import as OpenAPI specification, or fork existing)
- **OpenAPI generators** for client libraries
- **API documentation tools** like Swagger UI, Redoc
- **API testing tools** like Insomnia
- **Any OpenAPI-compatible tool**
