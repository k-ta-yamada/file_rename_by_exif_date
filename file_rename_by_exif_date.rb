# encoding: utf-8
# ####################################################################################################
# file_rename_by_exif_date.rb
#

# issue1 added this line!!

#
#   指定したフォルダ内のファイルについて、
#   exif情報の撮影日時（date_time_original）を利用したファイル名に変更する
#   exifがnilの場合や、ファイル名がすでに存在する場合は処理対象外
#   ファイル名は下記の形式とする
#   rename_file_name = date_time_original.strftime("%Y-%m-%d %H.%M.%S") + ".jpg"
#
#   処理概要

# this line is issue2 added
# hello ?
# issue2 end
# this is issue3
# conflict issue2

#     ファイル名の形式チェック（"%Y-%m-%d %H.%M.%S"のように数字がならんでいること）
#       形式に合致した場合は処理スキップ
#     exif情報の取得
#       取得できない場合は処理スキップ
#     exif情報の撮影日時を元にファイル名を生成（@exif.date_time_original.strftime("%Y-%m-%d %H.%M.%S") + ".jpg"）
#     生成したファイル名ですでにファイルが存在しないかチェック
#       存在した場合、処理スキップ
#     生成したファイル名にrenameする
# ####################################################################################################
require 'logger'
require 'exifr'
exit if (defined?(Ocra))

puts 'RENAME_EXEC? (yes:y / no:other)'
RENAME_EXEC = STDIN.gets.chomp == 'y' ? true : false
# RENAME_EXEC           = false
# 処理対象のディレクトリ
PROC_DIR              = ENV['HOME'] + '/Dropbox/Camera Uploads'
# １つ前のリネームファイル名称
rename_file_name_temp = ''
# リネームしたファイル数
rename_file_count     = 0

class Log
  # ログファイル名称
  LOG_FILE_NAME = File.basename($0) + '_' +
                  Time.now.strftime('%Y%m%d') + '.log'
  # ログ出力形式
  LOG_FORMATTER = proc { |severity, datetime, progname, msg|
    "#{datetime.strftime('%Y/%m/%d %H:%M:%S')} [#{severity}] #{msg}\n" }
  attr_reader :switch_stdout,
              :switch_logger
  # 初期化：引数がtrueの場合はファイルをstdoutの両方に出力
  def initialize(switch_stdout = false, switch_logger = false)
    # ログ出力先が無ければ作る
    Dir.mkdir('./log') unless Dir.exists?('./log')
    # loggerの設定
    @logger           = Logger.new('./log/' + LOG_FILE_NAME)
    @logger.formatter = LOG_FORMATTER
    @switch_stdout    = switch_stdout
    @switch_logger    = switch_logger
    logging 'logging start ' + $0
    logging
  end
  # ログの出力を行う
  def logging(s = '')
    puts s          if @switch_stdout
    @logger.info s  if @switch_logger
  end
end

class FileUtility
  attr_accessor :file_name,               # 処理対象のファイル名
                :exif_date_time_original, # exifの撮影日時
                :rename_file_name         # リネーム後のファイル名
  # 初期化
  def initialize(file)
    @file_name               ||= file
    @exif_date_time_original ||= nil
    @rename_file_name        ||= nil
  end
  # ファイル名の形式をチェック
  def file_name_match?
    if /^\d{4}-\d{2}-\d{2} \d{2}\.\d{2}\.\d{2}\.jpg$/.match(@file_name)
      $log_msg += "[#{self.class}]file_name_match!"
      $log.logging $log_msg
      return true
    end
    nil
  end
  # 必要な情報があるかチェック（今回はEXIFの撮影日）して、ファイル名を生成する
  def file_name_create
    # 撮影日時を取得する
    exif = EXIFR::JPEG.new(@file_name)
    if exif.date_time_original
      @exif_date_time_original = exif.date_time_original
      @rename_file_name = @exif_date_time_original.strftime("%Y-%m-%d %H.%M.%S") + '.jpg'
      return true
    else
      $log_msg += "[#{self.class}]information_exists!"
      $log.logging $log_msg
      return false
    end
    nil
  end
  # リネーム後のファイル名が既存の場合はスキップ
  def file_exists?(file)
    if File.exist?(file)
      $log_msg += "[#{self.class}]file_exists! => #{file}"
      $log.logging $log_msg
      return true
    end
    nil
  end
  # リネーム後のファイル名が直前の処理対象と同じ場合はスキップ
  def same_name?(temp_file, file)
    if temp_file == file
      $log_msg += "[#{self.class}]same_name!"
      $log.logging $log_msg
      return true
    end
    nil
  end
end


begin
  # loggerの生成
  $log = Log.new(true)

  # 作業ディレクトリを変更する（tip：logger生成前に変更すると、loggerが作業対象Dirにログはいちゃう！！）
  Dir.chdir(PROC_DIR)

  $log.logging "PROC_DIR=[#{Dir.pwd}]"
  $log.logging "RENAME_EXEC=[#{RENAME_EXEC}]"
  $log.logging

  puts
  puts "> infomation to execute confirm."
  puts ">   RENAME_EXEC =[#{RENAME_EXEC}]"
  puts ">   PROC_DIR    =[#{PROC_DIR}]"
  puts "> are you sure? and continue? (yes:y / no:other)"
  puts ">"
  # "y"が入力されたら処理を続行する。"y"以外は処理を終了する。
  exit unless gets.chomp == "y"
  puts


  # 拡張子が「.jpg」のファイル一覧を取得して、ファイル名でソートしておく
  # file_list = Dir.glob('*.jpg').sort_by{ |f| f }
  file_list = Dir.glob(['*.jpg','*.JPG']).sort

  # ファイル一覧を元に処理を開始する
  file_list.each.with_index(1) do |file, index|
    $log_msg =  ''                        # ToDo:グローバル！？かっこ悪いなぁ…
    $log_msg += sprintf('%03g',index)
    $log_msg += sprintf('[%-30s]',file)

    fileutil = FileUtility.new(file)

    # 現在のファイル名の形式をチェックし、形式に合致する場合は処理をスキップする。
    next if fileutil.file_name_match?

    # exifの撮影日時からファイル名を生成する => exifの撮影日時情報が無い場合はスキップ
    next unless fileutil.file_name_create

    # リネーム後のファイル名が既存の場合はスキップ
    next if fileutil.file_exists?(fileutil.rename_file_name)

    # リネーム後のファイル名が直前の処理対象と同じ場合はスキップ
    next if fileutil.same_name?(rename_file_name_temp, fileutil.rename_file_name)

    # renameする！！
    $log_msg += "rename to [#{fileutil.rename_file_name}]"
    if RENAME_EXEC
      File.rename(file,fileutil.rename_file_name)
      rename_file_count += 1
    end

    $log.logging $log_msg
    # 今回処理したファイルのファイル名をtempに保持
    rename_file_name_temp = fileutil.rename_file_name
  end

  # 処理終了ログ
  $log.logging
  $log.logging "  file count(s)         #{file_list.size}"
  $log.logging "  rename file count(s)  #{rename_file_count}"

rescue => e
  $log.logging e
ensure
  $log.logging
  $log.logging 'proc end.' + Time.now.to_s
  $log.logging
  puts 'press any key.'
  gets
end
