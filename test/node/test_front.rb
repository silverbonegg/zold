# Copyright (c) 2018 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'json'
require_relative '../test__helper'
require_relative 'fake_node'
require_relative '../../lib/zold/http'
require_relative '../../lib/zold/score'

class FrontTest < Minitest::Test
  def test_renders_public_pages
    FakeNode.new(log: $log).run(['--ignore-score-weakness']) do |port|
      {
        '200' => [
          '/robots.txt',
          '/',
          '/map.html',
          '/remotes'
        ],
        '404' => [
          '/this-is-absent',
          '/wallet/ffffeeeeddddcccc'
        ]
      }.each do |code, paths|
        paths.each do |p|
          uri = URI("http://localhost:#{port}#{p}")
          response = Zold::Http.new(uri).get
          assert_equal(
            code, response.code,
            "Invalid response code for #{uri}: #{response.message}"
          )
        end
      end
      score = Zold::Score.new(
        Time.now, 'localhost', 999,
        'NOPREFIX@ffffffffffffffff',
        strength: 1
      ).next.next.next.next
      Zold::Http.new(URI("http://localhost:#{port}/"), score).get
      json = JSON.parse(Zold::Http.new(URI("http://localhost:#{port}/remotes"), score).get.body)
      assert(json['all'].find { |r| r['host'] == 'localhost' })
    end
  end
end
