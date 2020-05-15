from abc import ABC, abstractmethod

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

class StorageService(ABC):
    """ Abstract base class for cloud storage.
        It defines a generic interface to implement

    Abstract Methods
    ----------------
    uploadFile
        Upload a file

    downloadFile
        Download a file

    file_exists
        Test if a file exists

    """

    def __init__(self):
        return


    @abstractmethod
    def uploadFile(self, filename: str, bucket: str, key: str, public: bool = False):
        pass


    @abstractmethod
    def downloadFile(self, bucket: str, key: str, filename: str):
        pass

    @abstractmethod
    def file_exists(self, bucket: str, key: str):
        pass


if __name__ == '__main__':
    pass
