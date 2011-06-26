require "test_helper"

class RequestFactoryTest < ActiveSupport::TestCase
  context "RequestFactory" do
    context '.copy_request' do
      setup do
        @project = Factory(:project)
        @project.project_metadata.update_attributes!(:budget_division => BudgetDivision.create!(:name => 'Test'))
        @request = Factory(:request_type).requests.create!(:project => @project, :asset => Factory(:well), :target_asset => Factory(:well))
      end

      context 'without quotas' do
        setup do
          @project.update_attributes!(:enforce_quotas => false)
          @copy = RequestFactory.copy_request(@request)
        end

        should 'have the same request type' do
          assert_equal @request.request_type, @copy.request_type
        end

        should 'have no target asset' do
          assert_nil @copy.target_asset
        end

        should 'be pending' do
          assert_equal 'pending', @copy.state
        end
      end

      context 'with quotas' do
        setup do
          @project.update_attributes!(:enforce_quotas => true)
        end

        context 'when has enough quota' do
          setup do
            @project.quotas.create!(:request_type => @request.request_type, :limit => 2)
            @request.reload
          end

          should 'not fail' do
            RequestFactory.copy_request(@request)
          end

          should 'fail if we request more than available' do
            RequestFactory.copy_request(@request)
            assert_raises(QuotaException) { RequestFactory.copy_request(@request) }
          end
        end

        context 'when insufficient quota' do
          setup do
            @project.quotas.destroy_all
          end

          should 'raise an exception' do
            assert_raises(QuotaException) { RequestFactory.copy_request(@request) }
          end
        end
      end
    end
  end
end
