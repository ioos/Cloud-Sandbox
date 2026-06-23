## LiveOcean Model Test Case

### Clone the repository to your save folder and run the setup script:
``` 
cd /save/ioos/<username>
git clone https://github.com/asascience/LiveOcean.git  
cd LiveOcean
./setup_LiveOcean.sh
```

### Run the test case using cloudflow workflow

```
cd ../Cloud-Sandbox/cloudflow
./workflows/workflow_main.py ../cluster.configs/ioos.cfg ../job.configs/liveocean.fcst >& /tmp/liveocean.log &
```

