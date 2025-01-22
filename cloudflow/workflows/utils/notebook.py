import json
import os

def get_notebook_name() -> str:
    """
    Return the full path and filename of the current jupyter notebook
    """
    try:
        import ipykernel
        from notebook.notebookapp import list_running_servers
    except ImportError as e:
        #log.exception('ImportError : This only runs in a Jupyter Notebook environment ' + str(e))
        return
        #raise Exception() from e

    import re
    import requests
    from urllib.parse import urljoin

    # Can also get the token this way
    #from traitlets import HasTraits, Unicode, getmembers
    #from jupyterhub.services.auth import HubAuth as auth
    #token = auth.api_token
    #print(token.default_value)  # This is the same as the os.env JUPYTERHUB_API_TOKEN

    try:
        kernel_id = re.search('kernel-(.*).json',
                              ipykernel.connect.get_connection_file()).group(1)
        servers = list_running_servers()
    except RuntimeError as e:
        #log.exception('RuntimeError : This only runs in a Jupyter Notebook environment ' + str(e))
        return

    token = os.getenv('JUPYTERHUB_API_TOKEN')

    for ss in servers:
        response = requests.get(urljoin(ss['url'], 'api/sessions'),
                              params={'token': token})
        
        response.raise_for_status()
        
        for nn in json.loads(response.text):
            if nn['kernel']['id'] == kernel_id:
                relative_path = nn['notebook']['path']
                return os.path.join(ss['notebook_dir'], relative_path)

        
def convert_nb2inject() -> str:
    ''' Converts the current notebook to an executable .py file
    
    Returns
    -------
    str : the full path and filename of the converted file
    
    '''
    
    try:
        import ipykernel
        import notebook.notebookapp
    except ImportError as e:
        #log.exception('ImportError : This only runs in a Jupyter Notebook environment ' + str(e))
        return

    from nbconvert import PythonExporter
    from nbconvert.writers import FilesWriter
    import nbformat
    #from traitlets.config import Config
    
    exporter = PythonExporter()
    
    nbfile = get_notebook_name()
    nb = nbformat.read(nbfile,nbformat.NO_CONVERT)
    
    start = 0
    # Don't use the last cell
    nb.cells = nb.cells[start:-2]
    
    (output, resources) = exporter.from_notebook_node(nb)
    
    filename = nbfile.split('/')[-1].split('.')[0]
    
    user = os.getenv("JUPYTERHUB_USER")
    
    # FIX: This should not be hardcoded
    tmpdir = f"/tmp/cloudflow/inject/{user}"
    
    if not os.path.exists(tmpdir):
        os.makedirs(tmpdir)
    
    outfile = f"{tmpdir}/{filename}"
    # Save to file
    writer = FilesWriter()
    writer.write(output, resources, outfile)
    
    return outfile + ".py"


def convert_notebook() -> str:
    ''' Converts the current notebook to an executable .py file
    
    Returns
    -------
    str : the full path and filename of the converted file
    
    '''

    try:
        import ipykernel
        import notebook.notebookapp
    except ImportError as e:
        #log.exception('ImportError : This only runs in a Jupyter Notebook environment ' + str(e))
        return

    from nbconvert import PythonExporter
    from nbconvert.writers import FilesWriter
    import nbformat

    exporter = PythonExporter()
    nbfile = get_notebook_name()
    nb = nbformat.read(nbfile,nbformat.NO_CONVERT)

    start = 0
    # Don't use the last cell
    nb.cells = nb.cells[start:-2]

    (output, resources) = exporter.from_notebook_node(nb)

    filename = nbfile.split('/')[-1].split('.')[0]

    outfile = filename

    # Save to file
    writer = FilesWriter()
    writer.write(output, resources, outfile)

    return outfile + ".py"



def inject(pyfile, platform: str = 'AWS'):
    ''' Uploads the notebook to S3 '''
    
    #from cloudflow.services.StorageService import StorageService
    from cloudflow.services.S3Storage import S3Storage
    
    #FIX: Make this cloud agnostic, need a way to set the current platform at runtime
    #FIX: Make this configurable at runtime, maybe from a config file on the machine

    user = os.getenv("JUPYTERHUB_USER")
    bucket='ioos-cloud-sandbox'
    bcktfolder=f'cloudflow/inject/{user}'
    
    filename = pyfile.split('/')[-1]
    #print(f"filename: {filename}")
    ss = S3Storage()
    #def uploadFile(self, filename: str, bucket: str, key: str, public: bool = False):
    ss.uploadFile(pyfile, bucket, f"{bcktfolder}/{filename}")
    return

