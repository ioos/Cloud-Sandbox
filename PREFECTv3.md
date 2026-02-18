# Prefect v3 Notes

If there is not a prefect server setup locally, prefect will start one 
automatically for your run. This can cause some issues with flow runs not 
finishing correctly if an Exception is encountered.

Recommended usage is to launch the prefect server as a background task and 
configure your account point to the local server.

We are working on setting up a daemon process to automatically launch when the 
system is booted. Alternatively, Prefect has some recommendations to run the 
server in a Docker container. This will be setup automatically in future
deployments.

### Start the prefect server

`prefect server start --background`

By default, the server will run on the localhost 127.0.0.1 port:4200

### Configure your profile to use the running server
`prefect config set PREFECT_API_URL="http://127.0.0.1:4200/api"`

### Additional settings to persist results
`prefect config set PREFECT_RESULTS_PERSIST_BY_DEFAULT="true"`
`prefect config set PREFECT_TASKS_DEFAULT_PERSIST_RESULT="true"`

### These settings will be added to ~/.prefect/profile.toml
```
export PREFECT_API_URL="http://localhost:4200/api"
export PREFECT_RESULTS_PERSIST_BY_DEFAULT = "true"
export PREFECT_TASKS_DEFAULT_PERSIST_RESULT = "true"
```

You can connect to the Prefect UI by using an ssh tunnel and connect
to the webserver on your machine.

Connect via SSH with a tunnel from 4200 to 4200
ssh -L local_port:destination_address:remote_port user@remote_server_addres

Example:
`ssh -i ~/.ssh/id_rsa -L 4200:localhost:4200 username@sandbox`

Open a web browser and open the URL:
`http://localhost:4200/dashboard`

There are also useful Prefect CLI tools:
prefect --help
prefect flow-runs ls

## To cancel a currently running flow:
Use prefect flow-run cancel flowrun-id. The id can be obtained from "prefect 
flow-runs ls" command. The Name was output at the beginning of the run and can
be found in your log output. 

Example output:

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃                                   ID ┃ Flow          ┃ Name           ┃ State     ┃ When         ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━━━━━━━━┩
│ 0c7df0f5-c2f4-425c-ae73-bfd53ca8ec50 │ hindcast-flow │ offbeat-impala │ RUNNING   │  1 hour ago  │
│ b66329bd-4e55-4ff5-a442-5ac2fffca3e6 │ hindcast-flow │ fuzzy-bug      │ COMPLETED │ 17 hours ago │
│ d92a59f0-7ac8-4b4f-9616-caade4a076cf │ hindcast-flow │ crafty-potoo   │ COMPLETED │ 20 hours ago │
│ 199e77cb-99ed-4b12-8b8b-15f88d091399 │ hindcast-flow │ perky-hawk     │ COMPLETED │ 21 hours ago │
└──────────────────────────────────────┴───────────────┴────────────────┴───────────┴──────────────┘
```

Example:
`prefect flow-run cancel 'a55a4804-9e3c-4042-8b59-b3b6b7618736'`


