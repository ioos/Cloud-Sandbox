from abc import ABC, abstractmethod

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

class StorageService(ABC):
    ''' This is an abstract base class for cloud storage.
        It defines a generic interface to implement
    '''

    def __init__(self):
        print('init stub')

    @abstractmethod
    def uploadFile(self, filename: str, bucket: str, key: str, public: bool = False):
        pass


if __name__ == '__main__':
    pass
