class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy]

  # GET /documents
  def index
    @documents = Document.current
  end

  # GET /documents/1
  def show
  end

  # GET /documents/new
  def new
    @document = Document.new
    @document.changed_by_id = current_user.id
  end

  # GET /documents/1/edit
  def edit
    @document.changed_by_id = current_user.id
  end

  # POST /documents
  def create
    @document = Document.new(document_params)
    prepare_document_for_saving(@document, nil)

    if params[:commit] != 'Preview' && @document.save
      redirect_to @document, notice: 'Document was successfully created.'
    else
      @document.valid?
      render :new
    end
  end

  # PATCH/PUT /documents/1
  def update
    new_document = Document.new(document_params)
    if params[:commit] == 'Preview'
      @document.assign_attributes(document_params)
      edit
      @document.valid?
      render :edit
      return
    end

    prepare_document_for_saving(new_document, @document.id)

    if new_document.save && @document.update_attribute(:is_current, false)
      redirect_to new_document, notice: 'Document was successfully updated.'
    else
      @document.assign_attributes(document_params)
      @document.valid?
      render :edit
    end
  end

  # DELETE /documents/1
  def destroy
    @document.destroy
    redirect_to documents_url, notice: 'Document was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document
      @document = Document.includes(changed_by: :player).find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def document_params
      params.require(:document).permit(:title, :subtitle, :content, :content_type, :authorized_by, :reason_changed, :url)
    end

    def prepare_document_for_saving(doc, prev_doc_id)
      doc.previous_version_id = prev_doc_id
      doc.changed_by_id = current_user.id
      doc.is_current = true
    end
end
