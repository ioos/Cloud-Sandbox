import os

from plotting import plot
from prefect import Flow, unmapped


def main():
    SOURCE = os.path.abspath('/Users/kenny.ells/data/dubai_his_arg.20191226')
    TARGET = os.path.abspath('tmp')
    FILES = sorted([os.path.join(SOURCE, f) for f in os.listdir(SOURCE)])
    FILES = FILES[:5]

    if not os.path.exists(TARGET):
        os.mkdir(TARGET)

    with Flow('plotting') as flow:
        plot.plot_roms.map(ncfile=FILES, target=unmapped(TARGET), varname=unmapped('temp'))

    # When calling dask-scheduler and dask-worker at the command line
    # address_tcp = 'tcp://10.90.69.73:8786'
    # print(address_tcp)
    # executor = DaskExecutor(address=address_tcp, local_processes=True, debug=True)

    # Defining the client in the script
    # client = Client()
    # print(client)
    # address_tcp = client.scheduler.address
    # executor = DaskExecutor(address=address_tcp)
    # flow.run(executor=executor)

    # Ignoring Dask
    flow.run()


if __name__ == '__main__':
    main()
