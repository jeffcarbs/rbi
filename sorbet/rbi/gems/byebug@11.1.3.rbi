# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `byebug` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module Byebug
  include(::Byebug::Helpers::ReflectionHelper)
  extend(::Byebug::Helpers::ReflectionHelper)
  extend(::Byebug)

  def displays; end
  def displays=(_arg0); end
  def init_file; end
  def init_file=(_arg0); end
  def mode; end
  def mode=(_arg0); end
  def run_init_script; end

  private

  def add_catchpoint(_arg0); end
  def breakpoints; end
  def catchpoints; end
  def contexts; end
  def current_context; end
  def debug_load(*_arg0); end
  def lock; end
  def post_mortem=(_arg0); end
  def post_mortem?; end
  def raised_exception; end
  def rc_dirs; end
  def run_rc_file(rc_file); end
  def start; end
  def started?; end
  def stop; end
  def stoppable?; end
  def thread_context(_arg0); end
  def tracing=(_arg0); end
  def tracing?; end
  def unlock; end
  def verbose=(_arg0); end
  def verbose?; end

  class << self
    def actual_control_port; end
    def actual_port; end
    def add_catchpoint(_arg0); end
    def attach; end
    def breakpoints; end
    def catchpoints; end
    def contexts; end
    def current_context; end
    def debug_load(*_arg0); end
    def handle_post_mortem; end
    def interrupt; end
    def load_settings; end
    def lock; end
    def parse_host_and_port(host_port_spec); end
    def post_mortem=(_arg0); end
    def post_mortem?; end
    def raised_exception; end
    def spawn(host = T.unsafe(nil), port = T.unsafe(nil)); end
    def start; end
    def start_client(host = T.unsafe(nil), port = T.unsafe(nil)); end
    def start_control(host = T.unsafe(nil), port = T.unsafe(nil)); end
    def start_server(host = T.unsafe(nil), port = T.unsafe(nil)); end
    def started?; end
    def stop; end
    def stoppable?; end
    def thread_context(_arg0); end
    def tracing=(_arg0); end
    def tracing?; end
    def unlock; end
    def verbose=(_arg0); end
    def verbose?; end
    def wait_connection; end
    def wait_connection=(_arg0); end

    private

    def client; end
    def control; end
    def server; end
  end
end

class Byebug::AutoirbSetting < ::Byebug::Setting
  def initialize; end

  def banner; end
  def value; end
  def value=(val); end
end

Byebug::AutoirbSetting::DEFAULT = T.let(T.unsafe(nil), Integer)

class Byebug::AutolistSetting < ::Byebug::Setting
  def initialize; end

  def banner; end
  def value; end
  def value=(val); end
end

Byebug::AutolistSetting::DEFAULT = T.let(T.unsafe(nil), Integer)

class Byebug::AutoprySetting < ::Byebug::Setting
  def initialize; end

  def banner; end
  def value; end
  def value=(val); end
end

Byebug::AutoprySetting::DEFAULT = T.let(T.unsafe(nil), Integer)

class Byebug::AutosaveSetting < ::Byebug::Setting
  def banner; end
end

Byebug::AutosaveSetting::DEFAULT = T.let(T.unsafe(nil), TrueClass)

class Byebug::BasenameSetting < ::Byebug::Setting
  def banner; end
end

class Byebug::BreakCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)
  include(::Byebug::Helpers::FileHelper)
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  private

  def add_line_breakpoint(file, line); end
  def line_breakpoint(location); end
  def method_breakpoint(location); end
  def target_object(str); end
  def valid_breakpoints_for(path, line); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::Breakpoint
  def initialize(_arg0, _arg1, _arg2); end

  def enabled=(_arg0); end
  def enabled?; end
  def expr; end
  def expr=(_arg0); end
  def hit_condition; end
  def hit_condition=(_arg0); end
  def hit_count; end
  def hit_value; end
  def hit_value=(_arg0); end
  def id; end
  def inspect; end
  def pos; end
  def source; end

  class << self
    def add(file, line, expr = T.unsafe(nil)); end
    def first; end
    def last; end
    def none?; end
    def potential_line?(filename, lineno); end
    def potential_lines(filename); end
    def remove(id); end

    private

    def potential_lines_with_trace_points(iseq, lines); end
    def potential_lines_without_trace_points(iseq, lines); end
  end
end

class Byebug::CallstyleSetting < ::Byebug::Setting
  def banner; end
  def to_s; end
end

Byebug::CallstyleSetting::DEFAULT = T.let(T.unsafe(nil), String)

class Byebug::CatchCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)

  def execute; end

  private

  def add(exception); end
  def clear; end
  def info; end
  def remove(exception); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::Command
  extend(::Forwardable)
  extend(::Byebug::Helpers::StringHelper)

  def initialize(processor, input = T.unsafe(nil)); end

  def arguments; end
  def confirm(*args, &block); end
  def context; end
  def errmsg(*args, &block); end
  def frame; end
  def help(*args, &block); end
  def match(*args, &block); end
  def pr(*args, &block); end
  def prc(*args, &block); end
  def print(*args, &block); end
  def processor; end
  def prv(*args, &block); end
  def puts(*args, &block); end

  class << self
    def allow_in_control; end
    def allow_in_control=(_arg0); end
    def allow_in_post_mortem; end
    def allow_in_post_mortem=(_arg0); end
    def always_run; end
    def always_run=(_arg0); end
    def columnize(width); end
    def help; end
    def match(input); end
    def to_s; end
  end
end

class Byebug::CommandList
  include(::Enumerable)

  def initialize(commands); end

  def each; end
  def match(input); end
  def to_s; end

  private

  def width; end
end

class Byebug::CommandNotFound < ::NoMethodError
  def initialize(input, parent = T.unsafe(nil)); end


  private

  def build_cmd(*args); end
  def help; end
  def name; end
end

class Byebug::CommandProcessor
  include(::Byebug::Helpers::EvalHelper)
  extend(::Forwardable)

  def initialize(context, interface = T.unsafe(nil)); end

  def at_breakpoint(brkpt); end
  def at_catchpoint(exception); end
  def at_end; end
  def at_line; end
  def at_return(return_value); end
  def at_tracing; end
  def command_list; end
  def commands(*args, &block); end
  def confirm(*args, &block); end
  def context; end
  def errmsg(*args, &block); end
  def frame(*args, &block); end
  def interface; end
  def pr(*args, &block); end
  def prc(*args, &block); end
  def prev_line; end
  def prev_line=(_arg0); end
  def printer; end
  def proceed!; end
  def process_commands; end
  def prv(*args, &block); end
  def puts(*args, &block); end

  protected

  def after_repl; end
  def before_repl; end
  def prompt; end
  def repl; end

  private

  def auto_cmds_for(run_level); end
  def run_auto_cmds(run_level); end
  def run_cmd(input); end
  def safely; end
end

class Byebug::ConditionCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::Context
  include(::Byebug::Helpers::FileHelper)
  extend(::Byebug::Helpers::PathHelper)
  extend(::Forwardable)

  def at_breakpoint(breakpoint); end
  def at_catchpoint(exception); end
  def at_end; end
  def at_line; end
  def at_return(return_value); end
  def at_tracing; end
  def backtrace; end
  def dead?; end
  def file(*args, &block); end
  def frame; end
  def frame=(pos); end
  def frame_binding(*_arg0); end
  def frame_class(*_arg0); end
  def frame_file(*_arg0); end
  def frame_line(*_arg0); end
  def frame_method(*_arg0); end
  def frame_self(*_arg0); end
  def full_location; end
  def ignored?; end
  def interrupt; end
  def line(*args, &block); end
  def location; end
  def resume; end
  def stack_size; end
  def step_into(*_arg0); end
  def step_out(*_arg0); end
  def step_over(*_arg0); end
  def stop_reason; end
  def suspend; end
  def suspended?; end
  def switch; end
  def thnum; end
  def thread; end
  def tracing; end
  def tracing=(_arg0); end

  private

  def ignored_file?(path); end
  def processor; end

  class << self
    def ignored_files; end
    def ignored_files=(_arg0); end
    def interface; end
    def interface=(_arg0); end
    def processor; end
    def processor=(_arg0); end
  end
end

class Byebug::ContinueCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  private

  def modifier; end
  def unconditionally?; end
  def until_line?; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::ControlProcessor < ::Byebug::CommandProcessor
  def commands; end
  def prompt; end
end

class Byebug::DebugCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::DebugThread < ::Thread
  class << self
    def inherited; end
  end
end

class Byebug::DeleteCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::DisableCommand < ::Byebug::Command
  include(::Byebug::Subcommands)
  extend(::Byebug::Helpers::ReflectionHelper)
  extend(::Byebug::Subcommands::ClassMethods)

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::DisableCommand::BreakpointsCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)
  include(::Byebug::Helpers::ToggleHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::DisableCommand::DisplayCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)
  include(::Byebug::Helpers::ToggleHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::DisplayCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)

  def execute; end

  private

  def display_expression(exp); end
  def eval_expr(expression); end
  def print_display_expressions; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::DownCommand < ::Byebug::Command
  include(::Byebug::Helpers::FrameHelper)
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::EditCommand < ::Byebug::Command
  def execute; end

  private

  def edit_error(type, file); end
  def editor; end
  def location(matched); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::EnableCommand < ::Byebug::Command
  include(::Byebug::Subcommands)
  extend(::Byebug::Helpers::ReflectionHelper)
  extend(::Byebug::Subcommands::ClassMethods)

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::EnableCommand::BreakpointsCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)
  include(::Byebug::Helpers::ToggleHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::EnableCommand::DisplayCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)
  include(::Byebug::Helpers::ToggleHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::FinishCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  private

  def max_frames; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::Frame
  include(::Byebug::Helpers::FileHelper)

  def initialize(context, pos); end

  def _binding; end
  def _class; end
  def _method; end
  def _self; end
  def args; end
  def c_frame?; end
  def current?; end
  def deco_args; end
  def deco_block; end
  def deco_call; end
  def deco_class; end
  def deco_file; end
  def deco_method; end
  def deco_pos; end
  def file; end
  def line; end
  def locals; end
  def mark; end
  def pos; end
  def to_hash; end

  private

  def c_args; end
  def prefix_and_default(arg_type); end
  def ruby_args; end
  def use_short_style?(arg); end
end

class Byebug::FrameCommand < ::Byebug::Command
  include(::Byebug::Helpers::FrameHelper)
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::FullpathSetting < ::Byebug::Setting
  def banner; end
end

Byebug::FullpathSetting::DEFAULT = T.let(T.unsafe(nil), TrueClass)

class Byebug::HelpCommand < ::Byebug::Command
  def execute; end

  private

  def command; end
  def help_for(input, cmd); end
  def help_for_all; end
  def subcommand; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

module Byebug::Helpers
end

module Byebug::Helpers::BinHelper
  def executable_file_extensions; end
  def find_executable(path, cmd); end
  def real_executable?(file); end
  def search_paths; end
  def which(cmd); end
end

module Byebug::Helpers::EvalHelper
  def error_eval(str, binding = T.unsafe(nil)); end
  def multiple_thread_eval(expression); end
  def separate_thread_eval(expression); end
  def silent_eval(str, binding = T.unsafe(nil)); end
  def warning_eval(str, binding = T.unsafe(nil)); end

  private

  def allowing_other_threads; end
  def error_msg(exception); end
  def in_new_thread; end
  def msg(exception); end
  def safe_eval(str, binding); end
  def safe_inspect(var); end
  def safe_to_s(var); end
  def warning_msg(exception); end
end

module Byebug::Helpers::FileHelper
  def get_line(filename, lineno); end
  def get_lines(filename); end
  def n_lines(filename); end
  def normalize(filename); end
  def shortpath(fullpath); end
  def virtual_file?(name); end
end

module Byebug::Helpers::FrameHelper
  def jump_frames(steps); end
  def switch_to_frame(frame); end

  private

  def adjust_frame(new_frame); end
  def direction(step); end
  def frame_err(msg); end
  def index_from_start(index); end
  def navigate_to_frame(jump_no); end
  def out_of_bounds?(pos); end
end

module Byebug::Helpers::ParseHelper
  def get_int(str, cmd, min = T.unsafe(nil), max = T.unsafe(nil)); end
  def parse_steps(str, cmd); end
  def syntax_valid?(code); end

  private

  def without_stderr; end
end

module Byebug::Helpers::PathHelper
  def all_files; end
  def bin_file; end
  def gem_files; end
  def lib_files; end
  def root_path; end
  def test_files; end

  private

  def glob_for(dir); end
end

module Byebug::Helpers::ReflectionHelper
  def commands; end
end

module Byebug::Helpers::StringHelper
  def camelize(str); end
  def deindent(str, leading_spaces: T.unsafe(nil)); end
  def prettify(str); end
end

module Byebug::Helpers::ThreadHelper
  def context_from_thread(thnum); end
  def current_thread?(ctx); end
  def display_context(ctx); end
  def thread_arguments(ctx); end

  private

  def debug_flag(ctx); end
  def location(ctx); end
  def status_flag(ctx); end
end

module Byebug::Helpers::ToggleHelper
  include(::Byebug::Helpers::ParseHelper)

  def enable_disable_breakpoints(is_enable, args); end
  def enable_disable_display(is_enable, args); end

  private

  def n_displays; end
  def select_breakpoints(is_enable, args); end
end

module Byebug::Helpers::VarHelper
  include(::Byebug::Helpers::EvalHelper)

  def var_args; end
  def var_global; end
  def var_instance(str); end
  def var_list(ary, binding = T.unsafe(nil)); end
  def var_local; end
end

class Byebug::HistfileSetting < ::Byebug::Setting
  def banner; end
  def to_s; end
end

Byebug::HistfileSetting::DEFAULT = T.let(T.unsafe(nil), String)

class Byebug::History
  def initialize; end

  def buffer; end
  def clear; end
  def default_max_size; end
  def ignore?(buf); end
  def last_ids(number); end
  def pop; end
  def push(cmd); end
  def restore; end
  def save; end
  def size; end
  def size=(_arg0); end
  def specific_max_size(number); end
  def to_s(n_cmds); end
end

class Byebug::HistoryCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::HistsizeSetting < ::Byebug::Setting
  def banner; end
  def to_s; end
end

Byebug::HistsizeSetting::DEFAULT = T.let(T.unsafe(nil), Integer)

class Byebug::InfoCommand < ::Byebug::Command
  include(::Byebug::Subcommands)
  extend(::Byebug::Helpers::ReflectionHelper)
  extend(::Byebug::Subcommands::ClassMethods)

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::InfoCommand::BreakpointsCommand < ::Byebug::Command
  def execute; end

  private

  def info_breakpoint(brkpt); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::InfoCommand::DisplayCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::InfoCommand::FileCommand < ::Byebug::Command
  include(::Byebug::Helpers::FileHelper)
  include(::Byebug::Helpers::StringHelper)

  def execute; end

  private

  def info_file_basic(file); end
  def info_file_breakpoints(file); end
  def info_file_mtime(file); end
  def info_file_sha1(file); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::InfoCommand::LineCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::InfoCommand::ProgramCommand < ::Byebug::Command
  def execute; end

  private

  def format_stop_reason(stop_reason); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::Interface
  include(::Byebug::Helpers::FileHelper)

  def initialize; end

  def autorestore; end
  def autosave; end
  def close; end
  def command_queue; end
  def command_queue=(_arg0); end
  def confirm(prompt); end
  def errmsg(message); end
  def error; end
  def history; end
  def history=(_arg0); end
  def input; end
  def last_if_empty(input); end
  def output; end
  def prepare_input(prompt); end
  def print(message); end
  def puts(message); end
  def read_command(prompt); end
  def read_file(filename); end
  def read_input(prompt, save_hist = T.unsafe(nil)); end

  private

  def split_commands(cmd_line); end
end

class Byebug::InterruptCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::IrbCommand < ::Byebug::Command
  def execute; end

  private

  def with_clean_argv; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::KillCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::LinetraceSetting < ::Byebug::Setting
  def banner; end
  def value; end
  def value=(val); end
end

class Byebug::ListCommand < ::Byebug::Command
  include(::Byebug::Helpers::FileHelper)
  include(::Byebug::Helpers::ParseHelper)

  def amend_final(*args, &block); end
  def execute; end
  def max_line(*args, &block); end
  def size(*args, &block); end

  private

  def auto_range(direction); end
  def display_lines(min, max); end
  def lower_bound(range); end
  def move(line, size, direction = T.unsafe(nil)); end
  def parse_range(input); end
  def range(input); end
  def source_file_formatter; end
  def split_range(str); end
  def upper_bound(range); end
  def valid_range?(first, last); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::ListsizeSetting < ::Byebug::Setting
  def banner; end
  def to_s; end
end

Byebug::ListsizeSetting::DEFAULT = T.let(T.unsafe(nil), Integer)

class Byebug::LocalInterface < ::Byebug::Interface
  def initialize; end

  def readline(prompt); end
  def with_repl_like_sigint; end
  def without_readline_completion; end
end

Byebug::LocalInterface::EOF_ALIAS = T.let(T.unsafe(nil), String)

class Byebug::MethodCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::NextCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

Byebug::PORT = T.let(T.unsafe(nil), Integer)

class Byebug::PostMortemProcessor < ::Byebug::CommandProcessor
  def commands; end
  def prompt; end
end

class Byebug::PostMortemSetting < ::Byebug::Setting
  def initialize; end

  def banner; end
  def value; end
  def value=(val); end
end

module Byebug::Printers
end

class Byebug::Printers::Base
  def type; end

  private

  def array_of_args(collection, &_block); end
  def contents; end
  def contents_files; end
  def locate(path); end
  def parts(path); end
  def translate(string, args = T.unsafe(nil)); end
end

class Byebug::Printers::Base::MissedArgument < ::StandardError
end

class Byebug::Printers::Base::MissedPath < ::StandardError
end

Byebug::Printers::Base::SEPARATOR = T.let(T.unsafe(nil), String)

class Byebug::Printers::Plain < ::Byebug::Printers::Base
  def print(path, args = T.unsafe(nil)); end
  def print_collection(path, collection, &block); end
  def print_variables(variables, *_unused); end

  private

  def contents_files; end
end

class Byebug::PryCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::QuitCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

module Byebug::Remote
end

class Byebug::Remote::Client
  def initialize(interface); end

  def interface; end
  def socket; end
  def start(host = T.unsafe(nil), port = T.unsafe(nil)); end
  def started?; end

  private

  def connect_at(host, port); end
end

class Byebug::Remote::Server
  def initialize(wait_connection:, &block); end

  def actual_port; end
  def start(host, port); end
  def wait_connection; end
end

class Byebug::RemoteInterface < ::Byebug::Interface
  def initialize(socket); end

  def close; end
  def confirm(prompt); end
  def print(message); end
  def puts(message); end
  def read_command(prompt); end
  def readline(prompt); end
end

class Byebug::RestartCommand < ::Byebug::Command
  include(::Byebug::Helpers::BinHelper)
  include(::Byebug::Helpers::PathHelper)

  def execute; end

  private

  def prepend_byebug_bin(cmd); end
  def prepend_ruby_bin(cmd); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::SaveCommand < ::Byebug::Command
  def execute; end

  private

  def save_breakpoints(file); end
  def save_catchpoints(file); end
  def save_displays(file); end
  def save_settings(file); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::SavefileSetting < ::Byebug::Setting
  def banner; end
  def to_s; end
end

Byebug::SavefileSetting::DEFAULT = T.let(T.unsafe(nil), String)

class Byebug::ScriptInterface < ::Byebug::Interface
  def initialize(file, verbose = T.unsafe(nil)); end

  def close; end
  def read_command(prompt); end
  def readline(*_arg0); end
end

class Byebug::ScriptProcessor < ::Byebug::CommandProcessor
  def after_repl; end
  def commands; end
  def prompt; end
  def repl; end

  private

  def without_exceptions; end
end

class Byebug::SetCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  private

  def get_onoff(arg, default); end

  class << self
    def description; end
    def help; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::Setting
  def initialize; end

  def boolean?; end
  def help; end
  def integer?; end
  def to_s; end
  def to_sym; end
  def value; end
  def value=(_arg0); end

  class << self
    def [](name); end
    def []=(name, value); end
    def find(shortcut); end
    def help_all; end
    def settings; end
  end
end

class Byebug::ShowCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def help; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::SkipCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def auto_run; end
  def execute; end
  def initialize_attributes; end
  def keep_execution; end
  def reset_attributes; end

  class << self
    def description; end
    def file_line; end
    def file_line=(_arg0); end
    def file_path; end
    def file_path=(_arg0); end
    def previous_autolist; end
    def regexp; end
    def restore_autolist; end
    def setup_autolist(value); end
    def short_description; end
  end
end

class Byebug::SourceCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::SourceFileFormatter
  include(::Byebug::Helpers::FileHelper)

  def initialize(file, annotator); end

  def amend(line, ceiling); end
  def amend_final(line); end
  def amend_initial(line); end
  def annotator; end
  def file; end
  def lines(min, max); end
  def lines_around(center); end
  def max_initial_line; end
  def max_line; end
  def range_around(center); end
  def range_from(min); end
  def size; end
end

class Byebug::StackOnErrorSetting < ::Byebug::Setting
  def banner; end
end

class Byebug::StepCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

module Byebug::Subcommands
  extend(::Forwardable)

  mixes_in_class_methods(::Byebug::Subcommands::ClassMethods)

  def execute; end
  def subcommand_list(*args, &block); end

  class << self
    def included(command); end
  end
end

module Byebug::Subcommands::ClassMethods
  include(::Byebug::Helpers::ReflectionHelper)

  def help; end
  def subcommand_list; end
end

class Byebug::ThreadCommand < ::Byebug::Command
  include(::Byebug::Subcommands)
  extend(::Byebug::Helpers::ReflectionHelper)
  extend(::Byebug::Subcommands::ClassMethods)

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::ThreadCommand::CurrentCommand < ::Byebug::Command
  include(::Byebug::Helpers::ThreadHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::ThreadCommand::ListCommand < ::Byebug::Command
  include(::Byebug::Helpers::ThreadHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::ThreadCommand::ResumeCommand < ::Byebug::Command
  include(::Byebug::Helpers::ThreadHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::ThreadCommand::StopCommand < ::Byebug::Command
  include(::Byebug::Helpers::ThreadHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::ThreadCommand::SwitchCommand < ::Byebug::Command
  include(::Byebug::Helpers::ThreadHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::ThreadsTable
end

class Byebug::TracevarCommand < ::Byebug::Command
  def execute; end

  private

  def on_change(name, value, stop); end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::UndisplayCommand < ::Byebug::Command
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::UntracevarCommand < ::Byebug::Command
  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::UpCommand < ::Byebug::Command
  include(::Byebug::Helpers::FrameHelper)
  include(::Byebug::Helpers::ParseHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::VarCommand < ::Byebug::Command
  include(::Byebug::Subcommands)
  extend(::Byebug::Helpers::ReflectionHelper)
  extend(::Byebug::Subcommands::ClassMethods)

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::VarCommand::AllCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)
  include(::Byebug::Helpers::VarHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::VarCommand::ArgsCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)
  include(::Byebug::Helpers::VarHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::VarCommand::ConstCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)

  def execute; end

  private

  def str_obj; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::VarCommand::GlobalCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)
  include(::Byebug::Helpers::VarHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::VarCommand::InstanceCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)
  include(::Byebug::Helpers::VarHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::VarCommand::LocalCommand < ::Byebug::Command
  include(::Byebug::Helpers::EvalHelper)
  include(::Byebug::Helpers::VarHelper)

  def execute; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::WhereCommand < ::Byebug::Command
  include(::Byebug::Helpers::FrameHelper)

  def execute; end

  private

  def print_backtrace; end

  class << self
    def description; end
    def regexp; end
    def short_description; end
  end
end

class Byebug::WidthSetting < ::Byebug::Setting
  def banner; end
  def to_s; end
end

Byebug::WidthSetting::DEFAULT = T.let(T.unsafe(nil), Integer)

class Exception
  def __bb_context; end
end

module Kernel
  def byebug; end
  def debugger; end
  def remote_byebug(host = T.unsafe(nil), port = T.unsafe(nil)); end
end
