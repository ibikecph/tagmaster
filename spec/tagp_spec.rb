require 'spec_helper'


RSpec.describe TagMaster::Tagp do

  before(:each) do
  end

  describe "#parse" do
    it "should handle Mark28 example from TagMaster manual" do
      event = "EVNTTAG 20070118143420957%04%02%BC%94%BA%15%E3%AA%08%00%7F%00"
      result = TagMaster::Tagp.parse event, Time.new(2007,1,18,14,35)
      
      expect(result).to be_a(TagMaster::EventTag)

      expect(result.line).to eq(event)
      expect(result.timestamp.to_f).to eq(1169130860.957)
      expect(result.data).to eq([0x04, 0x02, 0xBC, 0x94, 0xBA, 0x15, 0xE3, 0xAA, 0x08, 0x00, 0x7F, 0x00])
      expect(result.id).to eq(11478318)
      expect(result.type).to eq('Mark28')
      expect(result.subtype).to eq('MarkTag')
      expect(result.formatbits).to eq(2)
      expect(result.status).to eq(0)
    end

    it "should handle Mark28 example from TagMaster manual" do
      event = "EVNTTAG 20110808091520220%00%038^%88%E6%D2\L%00%7F%00"
      result = TagMaster::Tagp.parse event, Time.new(2007,1,18,14,35)
      
      expect(result).to be_a(TagMaster::EventTag)

      expect(result.line).to eq(event)
      #expect(result.timestamp.to_f).to eq(1169130860.957)
      #expect(result.data).to eq([0x04, 0x02, 0xBC, 0x94, 0xBA, 0x15, 0xE3, 0xAA, 0x08, 0x00, 0x7F, 0x00])
      expect(result.id).to eq(13506466)
      expect(result.type).to eq('Mark28')
      expect(result.subtype).to eq('MarkTag')
      expect(result.formatbits).to eq(3)
      expect(result.status).to eq(30)
    end

    it "should handle Mark28 example from TagMaster manual" do
      event = "EVNTTAG 20100120073247223%00%03!%ABs%C3%B9%80%E 8%00%7F%00     --> EVNT"
      result = TagMaster::Tagp.parse event, Time.new(2007,1,18,14,35)
      
      expect(result).to be_a(TagMaster::EventTag)

      expect(result.line).to eq(event)
      #expect(result.timestamp.to_f).to eq(1169130860.957)
      #expect(result.data).to eq([0x04, 0x02, 0xBC, 0x94, 0xBA, 0x15, 0xE3, 0xAA, 0x08, 0x00, 0x7F, 0x00])
      expect(result.id).to eq(13134556)
      expect(result.type).to eq('Mark28')
      expect(result.subtype).to eq('ScriptTag')
      expect(result.formatbits).to eq(3)
      expect(result.status).to eq(nil)
    end

    it "should handle Mark28 example from TagMaster manual" do
      event = "EVNTTAG 20070129111953513%00%F5%9C%F8%A3%8D'P%00%00"
      result = TagMaster::Tagp.parse event, Time.new(2007,1,18,14,35)
      
      expect(result).to be_a(TagMaster::EventTag)

      expect(result.line).to eq(event)
      #expect(result.timestamp.to_f).to eq(1169130860.957)
      #expect(result.data).to eq([0x04, 0x02, 0xBC, 0x94, 0xBA, 0x15, 0xE3, 0xAA, 0x08, 0x00, 0x7F, 0x00])
      expect(result.id).to eq(224869928)
      expect(result.type).to eq('Mark28')
      expect(result.subtype).to eq('MarkTag')
      expect(result.formatbits).to eq(53)
      expect(result.status).to eq(0)
    end


  end

end