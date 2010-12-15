#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this generator; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# Simple script to assess the amount of space saved by duplicate removal of
# entries in symbols' tables.

require 'elf/tools'

Options = [
          ]

def self.before_options
end

def self.after_options
  @files_mixing = []
  @files_nolfs = []
end

def self.analysis(file)
  Elf::File.open(file) do |elf|
    if elf.type != Elf::File::Type::Exec and
        elf.type != Elf::File::Type::Dyn
      puterror "#{file}: not an executable or dynamic file"
      next
    end

    if not elf.has_section?(".dynsym")
      puterror "#{file}: not a dynamically linked file"
      next
    end

    if elf.elf_class == Elf::Class::Elf64
      puterror "#{file}: testing 64-bit ELF files is meaningless"
      next
    end

    use_stat32 = false
    use_stat64 = false

    elf[".dynsym"].each do |symbol|
      next unless symbol.section == Elf::Section::Undef

      use_stat32 ||= (symbol.to_s =~ /^__(|l|f)xstat(|v?fs)$/)
      use_stat64 ||= (symbol.to_s =~ /^__(|l|f)xstat(|v?fs)64$/)
    end

    if use_stat32 and use_stat64
      @files_mixing << file
    elsif use_stat32 and not use_stat64
      @files_nolfs << file
    end
  end
end

def self.results
  if @files_mixing.size > 0
    puts "The following files are mixing LFS and non-LFS library calls:"
    puts "  " + @files_mixing.join("\n  ")
  end
  if @files_nolfs.size > 0
    puts "The following files are using non-LFS library calls:"
    puts "  " + @files_nolfs.join("\n  ")
  end
end