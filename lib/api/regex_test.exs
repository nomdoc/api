defmodule API.RegexTest do
  @moduledoc false

  use API.DataCase, async: true

  describe "handle_name/1" do
    test "must have a minimum length of 4." do
      refute Regex.match?(API.Regex.handle_name(), "abc")
      assert Regex.match?(API.Regex.handle_name(), "abcd")
    end

    test "must have a maximum length of 39." do
      # length of 40
      refute Regex.match?(API.Regex.handle_name(), "abcdefghijklmnopqrstuvwxyz0123456789abcd")

      # length of 39
      assert Regex.match?(API.Regex.handle_name(), "abcdefghijklmnopqrstuvwxyz0123456789abc")
    end

    test "must contain alphabets, numbers and hyphen only." do
      refute Regex.match?(API.Regex.handle_name(), " ~@#$%^&*()_=+/?'[]{}")
    end

    test "must start with a-z only." do
      refute Regex.match?(API.Regex.handle_name(), "93abc")
      refute Regex.match?(API.Regex.handle_name(), "-abc")
    end

    test "may contain one or more hyphen in between." do
      assert Regex.match?(API.Regex.handle_name(), "ab-cd")
      assert Regex.match?(API.Regex.handle_name(), "a-b-c-d")
    end

    test "cannot have trailing hyphen." do
      refute Regex.match?(API.Regex.handle_name(), "abcd-")
    end

    test "cannot include consecutive hyphens" do
      refute Regex.match?(API.Regex.handle_name(), "ab--cd")
    end
  end
end
