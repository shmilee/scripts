# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

from functools import lru_cache
from hashlib import sha256
from typing import Mapping, Union


class Base58(object):
    '''
    Bitcoin-compatible Base58 and Base58Check implementation
    Ref: https://github.com/keis/base58
    '''
    # 58 character alphabet used
    BITChars = b'123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
    XRPChars = b'rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz'

    def __init__(self, alphabet: bytes = BITChars) -> None:
        if type(alphabet) != bytes or len(alphabet) != 58:
            raise ValueError('Invalid alphabet for base58!')
        self.alphabet = alphabet
        self.base = 58  # len(alphabet)

    def encode(self, v: Union[str, bytes], str_encoding: str = 'utf-8',
               default_one: bool = False) -> bytes:
        """default_one: empty -> 1 ?"""
        v = v.encode(str_encoding) if isinstance(v, str) else v
        origlen = len(v)
        v = v.lstrip(b'\0')
        newlen = len(v)
        # first byte is most significant
        acc = int.from_bytes(v, byteorder='big')
        if not acc and default_one:
            result = self.alphabet[0:1]
        else:
            # acc: int -> result: str
            result = b""
            while acc:
                acc, idx = divmod(acc, self.base)
                result = self.alphabet[idx:idx+1] + result
        return self.alphabet[0:1] * (origlen - newlen) + result

    def encode_check(self, v: Union[str, bytes], str_encoding: str = 'utf-8',
                     default_one: bool = False) -> bytes:
        """Encode with a 4 character checksum"""
        v = v.encode(str_encoding) if isinstance(v, str) else v
        digest = sha256(sha256(v).digest()).digest()
        return self.encode(v + digest[:4], default_one=default_one)

    def encode_file(self, path: str, default_one: bool = False,
                    checksum: bool = False) -> bytes:
        func = self.encode_check if checksum else self.encode
        with open(path, 'rb') as f:  # rb: bytes, untranslate \r\n etc.
            return func(f.read(), default_one=default_one)

    @lru_cache()
    def _get_decode_map(self, autofix: bool) -> Mapping[int, int]:
        invmap = {char: index for index, char in enumerate(self.alphabet)}
        if autofix:
            groups = [b'0Oo', b'Il1']
            for group in groups:
                pivots = [c for c in group if c in invmap]
                if len(pivots) == 1:
                    for alternative in group:
                        invmap[alternative] = invmap[pivots[0]]
        return invmap

    def decode(self, v: Union[str, bytes], str_encoding: str = 'utf-8',
               autofix: bool = False) -> bytes:
        v = v.rstrip()
        v = v.encode(str_encoding) if isinstance(v, str) else v
        origlen = len(v)
        v = v.lstrip(self.alphabet[0:1])
        newlen = len(v)
        invmap = self._get_decode_map(autofix)
        # v: bytes -> acc: int
        acc = 0
        try:
            for char in v:
                acc = acc * self.base + invmap[char]
        except KeyError as e:
            raise ValueError("Invalid character {!r}".format(chr(e.args[0])))
        result = []
        while acc > 0:
            acc, mod = divmod(acc, 256)
            result.append(mod)
        return b'\0' * (origlen - newlen) + bytes(reversed(result))

    def decode_check(self, v: Union[str, bytes], str_encoding: str = 'utf-8',
                     autofix: bool = False) -> bytes:
        '''Decode and verify the checksum'''
        result = self.decode(v, str_encoding=str_encoding, autofix=autofix)
        result, check = result[:-4], result[-4:]
        digest = sha256(sha256(result).digest()).digest()
        if check != digest[:4]:
            raise ValueError("Invalid base58 checksum!")
        return result

    def decode_file(self, path: str, autofix: bool = False,
                    checksum: bool = False) -> bytes:
        func = self.decode_check if checksum else self.decode
        with open(path, 'rb') as f:  # bytes
            return func(f.read(), autofix=autofix)
