#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

'''
加密、解密 PDF 文件
Ref:
1. https://pypdf.readthedocs.io/en/stable/user/encryption-decryption.html
2. https://github.com/chenluda/pdf-password
'''

import os
import argparse
import time

from typing import (
    Any,
    Optional,
    Union,
    cast,
)
from tqdm import tqdm
from pypdf import PdfReader, PdfWriter
from pypdf.constants import Core as CO
from pypdf.generic import (
    ArrayObject,
    DictionaryObject,
    IndirectObject,
    NameObject,
    NullObject,
    NumberObject,
)


def get_pdf_reader(file):
    try:
        if os.path.isfile(file):
            return PdfReader(file)
        else:
            print(f'=> PDF {file} not found!')
            return None
    except Exception as err:
        print(f'=> Invalid PDF: {file}!')
        return None


def encrypt_pdf(input_pdf, output_pdf, user_password, **kwargs):
    """
    为 PDF 文件添加密码保护
    PdfWriter encrypt kwargs: owner_password, permissions_flag, algorithm
    """
    reader = get_pdf_reader(input_pdf)
    if not reader:
        return
    if reader.is_encrypted:
        print(f"=> PDF {input_pdf} has been encrypted.")
        return
    try:
        writer = PdfWriter(clone_from=reader)
        # Add a password to the new PDF
        writer.encrypt(user_password, **kwargs)
        # Save the new PDF to a file
        writer.write(output_pdf)
        print(f"=> Save the encrypted PDF to {output_pdf}.")
    except Exception as err:
        print(f"发生错误：{err}")


class MyPdfWriter(PdfWriter):
    '''
    custom :meth:`append` (:meth:`merge`) with progress bar
    '''

    def copy_from(
        self,
        reader: PdfReader,
        pages: Optional[list[int]] = None,
        import_outline: bool = True,
        excluded_fields: Optional[Union[list[str], tuple[str, ...]]] = (),
    ) -> None:
        """
        Copy the pages from the given PdfReader onto the end of the file.

        Args:
            reader: A PdfReader Object
            pages: can be a list of pages index
                to copy only the specified index of pages from the source
                document into the output document.
            import_outline: You may prevent the source document's
                outline (collection of outline items, previously referred to as
                'bookmarks') from being imported by specifying this as ``False``.
            excluded_fields: provide the list of fields/keys to be ignored
                if ``/Annots`` is part of the list, the annotation will be ignored
                if ``/B`` is part of the list, the articles will be ignored

        Raises:
            TypeError: The pages attribute is not configured properly

        """
        if excluded_fields is None:
            excluded_fields = ()
        if not isinstance(pages, (list, range)):
            raise TypeError('"pages" must be a list or a range')

        t0 = time.time()
        srcpages = {}
        for page in tqdm(pages, desc="正在复制"):
            pg = reader.pages[page]
            assert pg.indirect_reference is not None
            srcpages[pg.indirect_reference.idnum] = self.add_page(
                pg, [*list(excluded_fields), 1, "/B", 1, "/Annots"]  # type: ignore
            )
            srcpages[pg.indirect_reference.idnum].original_page = pg
        # cost 4s
        #print(f'cost-time1={time.time()-t0}s')
        t0 = time.time()  # reset

        reader._named_destinations = (
            reader.named_destinations
        )  # need for the outline processing below

        arr: Any

        def _process_named_dests(dest: Any) -> None:
            arr = dest.dest_array
            if "/Names" in self._root_object and dest["/Title"] in cast(
                list[Any],
                cast(
                    DictionaryObject,
                    cast(DictionaryObject, self._root_object["/Names"]).get("/Dests", DictionaryObject()),
                ).get("/Names", DictionaryObject()),
            ):
                # already exists: should not duplicate it
                pass
            elif dest["/Page"] is None or isinstance(dest["/Page"], NullObject):
                pass
            elif isinstance(dest["/Page"], int):
                # the page reference is a page number normally not a PDF Reference
                # page numbers as int are normally accepted only in external goto
                try:
                    p = reader.pages[dest["/Page"]]
                except IndexError:
                    return
                assert p.indirect_reference is not None
                try:
                    arr[NumberObject(0)] = NumberObject(
                        srcpages[p.indirect_reference.idnum].page_number
                    )
                    self.add_named_destination_array(dest["/Title"], arr)
                except KeyError:
                    pass
            elif dest["/Page"].indirect_reference.idnum in srcpages:
                arr[NumberObject(0)] = srcpages[
                    dest["/Page"].indirect_reference.idnum
                ].indirect_reference
                self.add_named_destination_array(dest["/Title"], arr)

        for dest in reader._named_destinations.values():
            _process_named_dests(dest)
        # cost 0.2s
        #print(f'cost-time2={time.time()-t0}s')
        t0 = time.time() # reset

        outline_item_typ = self.get_outline_root()

        _ro = reader.root_object
        if import_outline and CO.OUTLINES in _ro:
            outline = self._get_filtered_outline(
                _ro.get(CO.OUTLINES, None), srcpages, reader
            )
            self._insert_filtered_outline(
                outline, outline_item_typ, None
            )  # TODO: use before parameter
        # cost 0.08s
        #print(f'cost-time3={time.time()-t0}s')
        t0 = time.time() # reset

        if "/Annots" not in excluded_fields:
            for pag in srcpages.values():
                lst = self._insert_filtered_annotations(
                    pag.original_page.get("/Annots", []), pag, srcpages, reader
                )
                if len(lst) > 0:
                    pag[NameObject("/Annots")] = lst
                self.clean_page(pag)

        if "/AcroForm" in _ro and _ro["/AcroForm"] is not None:
            if "/AcroForm" not in self._root_object:
                self._root_object[NameObject("/AcroForm")] = self._add_object(
                    cast(
                        DictionaryObject,
                        reader.root_object["/AcroForm"],
                    ).clone(self, False, ("/Fields",))
                )
                arr = ArrayObject()
            else:
                arr = cast(
                    ArrayObject,
                    cast(DictionaryObject, self._root_object["/AcroForm"])["/Fields"],
                )
            trslat = self._id_translated[id(reader)]
            try:
                for f in reader.root_object["/AcroForm"]["/Fields"]:  # type: ignore
                    try:
                        ind = IndirectObject(trslat[f.idnum], 0, self)
                        if ind not in arr:
                            arr.append(ind)
                    except KeyError:
                        # for trslat[] which mean the field has not be copied
                        # through the page
                        pass
            except KeyError:  # for /Acroform or /Fields are not existing
                arr = self._add_object(ArrayObject())
            cast(DictionaryObject, self._root_object["/AcroForm"])[
                NameObject("/Fields")
            ] = arr

        if "/B" not in excluded_fields:
            self.add_filtered_articles("", srcpages, reader)
        # cost 0.02s
        #print(f'cost-time4={time.time()-t0}s')


class PdfCracker(object):
    '''
    破解 PDF 文件的密码保护
    Crack password-protected PDF file
    '''

    def __init__(self, input_pdf, dictionary_folder):
        reader = get_pdf_reader(input_pdf)
        if reader:
            self.reader = reader
        else:
            raise ValueError(f'Invalid PDF: {input_pdf}!') from None
        # 遍历字典文件夹
        dictionary_files, count = [], 0
        valid_extensions = ('.txt', '.dic', '.lst')  # 只包含文本文件
        for root, _, files in os.walk(dictionary_folder):
            for file in files:
                if file.lower().endswith(valid_extensions):
                    dictionary_files.append(os.path.join(root, file))
                    count = len(dictionary_files)
                    print(f"{count}) 添加字典文件: {dictionary_files[-1]}")
        self.dictionary_files = sorted(dictionary_files)
        # 检查密码
        if self.reader.is_encrypted:
            self.is_decrypted = False
            # 尝试空密码解密，若仅有 owner_password，则可直接去密
            if self.reader.decrypt(''):
                print("=》空密码解密成功")
                self.is_decrypted = True
                self.password = ''
        else:
            self.is_decrypted = True
            self.password = None

    def crack_password(self):
        if self.is_decrypted:
            return
        open_kwargs = dict(encoding='utf-8', errors='ignore')
        try:
            for idx, dict_file in enumerate(self.dictionary_files, 1):
                desc = f'尝试字典[{idx}/{len(self.dictionary_files)}], 进度'
                try:
                    with open(dict_file, 'r', **open_kwargs) as pwd_file:
                        passwords = pwd_file.readlines()
                    for pwd in tqdm(passwords, desc=f'🔎 {desc}'):
                        pwd = pwd.rstrip('\n\r')  # 只移除换行符
                        if self.reader.decrypt(pwd):  # 0, 1 or 2
                            self.is_decrypted = True
                            self.password = pwd
                            break
                except (UnicodeDecodeError, IOError) as err:
                    print(f"=》⚠️ 无法读取字典文件 {dict_file}: {err}")
                if self.is_decrypted:
                    break
            if self.is_decrypted:
                print(f"✅ 找到密码: {self.password}")
        except KeyboardInterrupt:
            print("\n⛔ 用户中断")

    @staticmethod
    def parse_pages_spec(pages_spec):
        """
        解析页面规格字符串，支持以下格式：
        1. 单个页码: "10" -> [9]
        2. 范围: "1-20" -> range(0, 20)
        3. 逗号分隔: "31,64,55" -> [30, 63, 54]
        4. 混合: "1-20,31,64,55" -> [0-19, 30, 63, 54]
        """
        if not pages_spec:
            return []
        pages = set()
        # 按逗号分割不同的规格
        specs = pages_spec.split(',')
        for spec in specs:
            spec = spec.strip()
            if not spec:
                continue
            # 检查是否是范围格式 (如 "1-20")
            if '-' in spec:
                try:
                    start, end = map(int, spec.split('-'))
                    # 转换为0基索引，并确保end是包含的
                    for page_num in range(start - 1, end):
                        pages.add(page_num)
                except ValueError:
                    print(f"警告: 无效的范围格式 '{spec}'，跳过")
                    continue
            else:
                # 单个页码
                try:
                    page_num = int(spec) - 1  # 转换为0基索引
                    if page_num >= 0:
                        pages.add(page_num)
                except ValueError:
                    print(f"警告: 无效的页码 '{spec}'，跳过")
                    continue
        # 排序并返回列表
        return sorted(pages)

    def save(self, output_pdf, pages=None):
        '''
        pages: str, 传给 :meth:`parse_pages_spec` 获取页码索引
        注意：用户输入的页码是从1开始，会转换为从0开始的Python索引
        '''
        if not self.is_decrypted:
            print('=》未解密 PDF 无法编辑!')
            return
        try:
            writer = MyPdfWriter()  # 空白 PDF
            # 复制原始PDF的元数据
            if self.reader.metadata:
                writer.metadata = self.reader.metadata
            if self.reader.xmp_metadata:
                writer.xmp_metadata = self.reader.xmp_metadata
            N = len(self.reader.pages)
            pages = self.parse_pages_spec(pages)
            if pages:
                pages = [i for i in pages if 0 <= i < N]
            else:
                pages = range(N)
            print(f"=》新 PDF 共 {len(pages)} 页")
            # 复制原始PDF的页、目录书签，import_outline (aka bookmarks)
            # ref: https://github.com/py-pdf/pypdf/discussions/1625
            writer.copy_from(self.reader, pages=pages, import_outline=True)
            print(f"\r=》保存到文件 {output_pdf} ...", end=' ')
            writer.write(output_pdf)
            print('完成。')
        except Exception as err:
            print(f"发生错误：{err}")


def main():
    parser = argparse.ArgumentParser(
        prog='PDFPasswordTool.py',
        description="Tool to encrypt or crack PDF passwords",
        formatter_class=argparse.RawTextHelpFormatter,
        add_help=False
    )
    comgroup = parser.add_argument_group('common options')
    comgroup.add_argument('command', type=str, nargs='?',
                          choices=['encrypt', 'crack'],
                          help='Choose a command to execute')
    comgroup.add_argument('-i', '--input', type=str,  # required=True,
                          help='Input PDF file')
    comgroup.add_argument('-o', '--output', type=str,
                          help='Output encrypted or decrypted PDF file')
    comgroup.add_argument('-h', '--help', action='store_true',
                          help='Show help message and exit')
    # 加密组
    encgroup = parser.add_argument_group('encrypt options')
    encgroup.add_argument('-p', '--password', type=str,
                          help='Password for encryption')
    encgroup.add_argument('--owner-password', type=str,
                          help='Owner password (optional)')
    encgroup.add_argument('--algorithm', type=str,
                          choices=['AES-256', 'AES-128', 'RC4-128'],
                          default='AES-256',
                          help='Encryption algorithm')
    encgroup.add_argument('--permissions', type=int,
                          help='Permissions flag (integer),\n'
                          'see Table 3.20 of the PDF 1.7 specification')
    # 解密/破解组
    crkgroup = parser.add_argument_group('crack options')
    crkgroup.add_argument('-d', '--dict-dir', type=str, metavar='DIR',
                          help="Password dictionary directory")
    crkgroup.add_argument('--pages', type=str,
                          help='Output page numbers to extract (optional)\n'
                          'Start from 1, supported formats:\n'
                          '  1) range (1-5);\n'
                          '  2) comma-separated (8,9,10);\n'
                          '  3) mixed (1-5,8,9,10)')

    def print_help_examples():
        parser.print_help()
        print("\nExamples:")
        print("  PDFPasswordTool.py encrypt -i input.pdf -o encrypted.pdf -p mypassword")
        print("  PDFPasswordTool.py crack -i encrypted.pdf -d ./dictionaries --pages 1-5,8,6,5 -o decrypted.pdf")

    args = parser.parse_args()
    # print(args)
    if args.help:
        print_help_examples()
        return

    def check_required_arguments(*arguments):
        lost_required_arguments = False
        for attr in arguments:
            if not getattr(args, attr):
                opt = attr.replace('_', '-')
                print(f"=> ⚠️  The '--{opt}' argument is required!")
                lost_required_arguments = True
        if lost_required_arguments:
            print_help_examples()
        return lost_required_arguments

    if args.command == 'encrypt':
        if check_required_arguments('input', 'output', 'password'):
            return
        encrypt_kwargs = {}
        if args.owner_password:
            encrypt_kwargs['owner_password'] = args.owner_password
        if args.permissions:
            encrypt_kwargs['permissions_flag'] = args.permissions
        if args.algorithm:
            encrypt_kwargs['algorithm'] = args.algorithm
        encrypt_pdf(args.input, args.output, args.password, **encrypt_kwargs)
    elif args.command == 'crack':
        if check_required_arguments('input', 'dict_dir'):
            return
        cracker = PdfCracker(args.input, args.dict_dir)
        if not cracker.is_decrypted:
            cracker.crack_password()
        if args.output:
            cracker.save(args.output, pages=args.pages)
    else:
        print_help_examples()


if __name__ == '__main__':
    main()
