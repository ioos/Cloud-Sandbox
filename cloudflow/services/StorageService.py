from abc import ABC, abstractmethod

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


class StorageService(ABC):
    """ Abstract base class for cloud storage.
        It defines a generic interface to implement
    """

    def __init__(self):
        return


    @abstractmethod
    def uploadFile(self, filename: str, bucket: str, key: str, public: bool = False):
        """ Interface to upload a file to the storage provider

        Parameters
        ----------
        filename : str
            The path and filename to upload

        bucket : str
            The S3 bucket to use

        key : str
            The key to store the file as

        public : bool
            If file should be made publicly accessible or not
        """
        pass


    @abstractmethod
    def downloadFile(self, bucket: str, key: str, filename: str):
        """ Interface to download a file from the storage provider

        Parameters
        ----------
        bucket : str
            The S3 bucket to use

        key : str
            The key for the file

        filename : str
            The path and filename to save the file as
        """
        pass


    @abstractmethod
    def file_exists(self, bucket: str, key: str):
        """ Test if the specified file exists in the storage provider bucket

        Parameters
        ----------
        bucket : str
            The S3 bucket to use

        key : str
            The S3 key for the file to check

        Returns
        -------
        bool
            True if file exists
            False if file does not exist

        """
        pass


if __name__ == '__main__':
    pass
