%module sentencepiece
%include exception.i

%{
#include <cmath>
#include <sentencepiece_processor.h>
#include <sentencepiece_trainer.h>

namespace {
PyObject* kStringInput = reinterpret_cast<PyObject* >(0x1);
PyObject* kUnicodeInput = reinterpret_cast<PyObject* >(0x2);

class PyInputString {
 public:
  explicit PyInputString(PyObject* obj) {
#if PY_VERSION_HEX >= 0x03000000
    if (PyUnicode_Check(obj)) {
      str_ = const_cast<char *>(PyUnicode_AsUTF8AndSize(obj, &size_));
      input_type_ = kUnicodeInput;
    } else if (PyBytes_Check(obj)) {
      PyBytes_AsStringAndSize(obj, &str_, &size_);
      input_type_ = kStringInput;
    }
#else
    if (PyUnicode_Check(obj)) {
      utf8_obj_ = PyUnicode_AsUTF8String(obj);
      PyString_AsStringAndSize(utf8_obj_, &str_, &size_);
      input_type_ = kUnicodeInput;
    } else if (PyString_Check(obj)) {
      PyString_AsStringAndSize(obj, &str_, &size_);
      input_type_ = kStringInput;
    }
#endif
    else {
      str_ = nullptr;
    }
  }
  virtual ~PyInputString() {
    Py_XDECREF(utf8_obj_);
  }
  const char* str() const { return str_; }
  Py_ssize_t size() const { return size_; }
  bool IsAvalable() const { return str_ != nullptr; }
  PyObject *input_type() const { return input_type_; }

 private:
  PyObject* utf8_obj_ = nullptr;
  PyObject* input_type_ = nullptr;
  char* str_ = nullptr;
  Py_ssize_t size_ = 0;
};

PyObject* MakePyOutputString(const std::string& output, PyObject *resultobj) {
#if PY_VERSION_HEX >= 0x03000000
  return resultobj == kStringInput ?
      PyBytes_FromStringAndSize(output.data(), output.size()) :
      PyUnicode_FromStringAndSize(output.data(), output.size());
#else
   return resultobj == kUnicodeInput ?
       PyUnicode_FromStringAndSize(output.data(), output.size()) :
       PyString_FromStringAndSize(output.data(), output.size());
#endif
}

int ToSwigError(sentencepiece::util::error::Code code) {
  switch (code) {
    case sentencepiece::util::error::NOT_FOUND:
      return SWIG_IOError;
    case sentencepiece::util::error::OUT_OF_RANGE:
      return SWIG_IndexError;
    case sentencepiece::util::error::INVALID_ARGUMENT:
      return SWIG_SyntaxError;
    default:
      return SWIG_RuntimeError;
  }
  return SWIG_RuntimeError;
}

#define THROW_IF_ERROR(expr)                            \
  do {                                                  \
    const sentencepiece::util::Status _status = expr;   \
    if (!_status.ok()) throw _status;                   \
  } while (0)

}  // namespace
%}

%exception {
  try { $action }
  catch (const sentencepiece::util::Status &status) {
    SWIG_exception(ToSwigError(status.code()), status.ToString().c_str());
  }
}

%ignore sentencepiece::util::Status;
%ignore sentencepiece::util::error::Code;

%ignore sentencepiece::SentencePieceProcessor::status() const;
%ignore sentencepiece::SentencePieceProcessor::Encode(std::string const &, std::vector<std::string>*) const;
%ignore sentencepiece::SentencePieceProcessor::Encode(std::string const &, std::vector<int>*) const;
%ignore sentencepiece::SentencePieceProcessor::Encode(std::string const &, SentencePieceText *) const;
%ignore sentencepiece::SentencePieceProcessor::SampleEncode(std::string const &,int,float, std::vector< std::string > *) const;
%ignore sentencepiece::SentencePieceProcessor::SampleEncode(std::string const &,int,float, std::vector< int > *) const;
%ignore sentencepiece::SentencePieceProcessor::SampleEncode(std::string const &,int,float, SentencePieceText *) const;
%ignore sentencepiece::SentencePieceProcessor::NBestEncode(std::string const &,int, NBestSentencePieceText *) const;
%ignore sentencepiece::SentencePieceProcessor::NBestEncode(std::string const &,int,std::vector< std::vector< std::string > > *) const;
%ignore sentencepiece::SentencePieceProcessor::NBestEncode(std::string const &,int,std::vector< std::vector< int > > *) const;
%ignore sentencepiece::SentencePieceProcessor::Decode(std::vector<std::string> const &, std::string *) const;
%ignore sentencepiece::SentencePieceProcessor::Decode(std::vector<int> const &, std::string *) const;
%ignore sentencepiece::SentencePieceProcessor::Decode(std::vector<std::string> const &, SentencePieceText *) const;
%ignore sentencepiece::SentencePieceProcessor::Decode(std::vector<int> const &, SentencePieceText *) const;
%ignore sentencepiece::SentencePieceProcessor::model_proto;
%ignore sentencepiece::SentencePieceProcessor::Load(std::istream *);
%ignore sentencepiece::SentencePieceProcessor::LoadOrDie(std::istream *);
%ignore sentencepiece::SentencePieceProcessor::Load(const ModelProto &);
%ignore sentencepiece::SentencePieceProcessor::Load(std::unique_ptr<ModelProto> &&);
%ignore sentencepiece::SentencePieceProcessor::model_proto();
%ignore sentencepiece::SentencePieceTrainer::Train(const TrainerSpec &);
%ignore sentencepiece::SentencePieceTrainer::Train(const TrainerSpec &, const NormalizerSpec &);
%ignore sentencepiece::SentencePieceTrainer::GetNormalizerSpec(const std::string &);
%ignore sentencepiece::SentencePieceTrainer::PopulateNormalizerSpec(NormalizerSpec *);
%ignore sentencepiece::SentencePieceTrainer::MergeSpecsFromArgs(const std::string &,
                                                                TrainerSpec *, NormalizerSpec *);
%ignore sentencepiece::SentencePieceTrainer::SetProtoField(const std::string &,
                                                           const std::string &,
                                                           google::protobuf::Message *message);

%extend sentencepiece::SentencePieceTrainer {
  static util::Status train(const std::string &args) {
    return sentencepiece::SentencePieceTrainer::Train(args);
  }
}

%extend sentencepiece::SentencePieceProcessor {
  util::Status load(const std::string &filename) {
    return $self->Load(filename);
  }

  util::Status _set_encode_extra_options(const std::string &extra_option) {
    return $self->SetEncodeExtraOptions(extra_option);
  }

  util::Status _set_decode_extra_options(const std::string &extra_option) {
    return $self->SetDecodeExtraOptions(extra_option);
  }

  util::Status set_vocabulary(
      const std::vector<std::string> &valid_vocab) {
    return $self->SetVocabulary(valid_vocab);
  }

  util::Status reset_vocabulary() {
    return $self->ResetVocabulary();
  }

  util::Status load_vocabulary(const std::string &filename,
                               int threshold) {
    return $self->LoadVocabulary(filename, threshold);
  }

  std::vector<std::string> encode(const std::string& input) const {
    return $self->EncodeAsPieces(input);
  }

  std::vector<std::string> encode_as_pieces(const std::string& input) const {
    return $self->EncodeAsPieces(input);
  }

  std::vector<int> encode_as_ids(const std::string& input) const {
    return $self->EncodeAsIds(input);
  }

  std::vector<std::vector<std::string>> nbest_encode(const std::string& input,
                                                       int nbest_size) const {
    return $self->NBestEncodeAsPieces(input, nbest_size);
  }

  std::vector<std::vector<std::string>> nbest_encode_as_pieces(
      const std::string& input, int nbest_size) const {
    return $self->NBestEncodeAsPieces(input, nbest_size);
  }

  std::vector<std::vector<int>> nbest_encode_as_ids(const std::string& input,
                                                    int nbest_size) const {
    return $self->NBestEncodeAsIds(input, nbest_size);
  }

  std::vector<std::string> sample_encode(const std::string& input,
                                         int nbest_size, float alpha) const {
    return $self->SampleEncodeAsPieces(input, nbest_size, alpha);
  }

  std::vector<std::string> sample_encode_as_pieces(const std::string& input,
                                            int nbest_size, float alpha) const {
    return $self->SampleEncodeAsPieces(input, nbest_size, alpha);
  }

  std::vector<int> sample_encode_as_ids(const std::string& input,
                                 int nbest_size, float alpha) const {
    return $self->SampleEncodeAsIds(input, nbest_size, alpha);
  }

  std::string decode(const std::vector<std::string>& input) const {
    return $self->DecodePieces(input);
  }

  std::string decode_pieces(const std::vector<std::string>& input) const {
    return $self->DecodePieces(input);
  }

  std::string decode_ids(const std::vector<int>& input) const {
    return $self->DecodeIds(input);
  }

  std::vector<std::string> Encode(const std::string& input) const {
    return $self->EncodeAsPieces(input);
  }

  int get_piece_size() const {
    return $self->GetPieceSize();
  }

  int piece_to_id(const std::string &piece) const {
    return $self->PieceToId(piece);
  }

  std::string id_to_piece(int id) const {
    return $self->IdToPiece(id);
  }

  float get_score(int id) const {
    return $self->GetScore(id);
  }

  bool is_unknown(int id) const {
    return $self->IsUnused(id);
  }

  bool is_control(int id) const {
    return $self->IsControl(id);
  }

  bool is_unused(int id) const {
    return $self->IsUnused(id);
  }

  std::vector<std::vector<std::string>> NBestEncode(const std::string& input, int nbest_size) const {
    return $self->NBestEncodeAsPieces(input, nbest_size);
  }

  std::vector<std::string> SampleEncode(const std::string& input, int nbest_size, float alpha) const {
    return $self->SampleEncodeAsPieces(input, nbest_size, alpha);
  }

  std::string Decode(const std::vector<std::string>& input) const {
    return $self->DecodePieces(input);
  }

  int __len__() {
    return $self->GetPieceSize();
  }

  int __getitem__(const std::string& key) const {
    return $self->PieceToId(key);
  }
}

%typemap(out) std::vector<int> {
  $result = PyList_New($1.size());
  for (size_t i = 0; i < $1.size(); ++i) {
    PyList_SetItem($result, i, PyInt_FromLong(static_cast<long>($1[i])));
  }
}

%typemap(out) std::vector<std::vector<int>> {
  $result = PyList_New($1.size());
  for (size_t i = 0; i < $1.size(); ++i) {
    PyObject *obj = PyList_New($1[i].size());
    for (size_t j = 0; j < $1[i].size(); ++j) {
      PyList_SetItem(obj, j, PyInt_FromLong(static_cast<long>($1[i][j])));
    }
    PyList_SetItem($result, i, obj);
  }
}

%typemap(out) std::vector<std::string> {
  PyObject *input_type = resultobj;
  $result = PyList_New($1.size());
  for (size_t i = 0; i < $1.size(); ++i) {
    PyList_SetItem($result, i, MakePyOutputString($1[i], input_type));
  }
}

%typemap(out) std::vector<std::vector<std::string>> {
  PyObject *input_type = resultobj;
  $result = PyList_New($1.size());
  for (size_t i = 0; i < $1.size(); ++i) {
    PyObject *obj = PyList_New($1[i].size());
    for (size_t j = 0; j < $1[i].size(); ++j) {
      PyList_SetItem(obj, j, MakePyOutputString($1[i][j], input_type));
    }
    PyList_SetItem($result, i, obj);
  }
}

%typemap(out) std::string {
  PyObject *input_type = resultobj;
  $result = MakePyOutputString($1, input_type);
}

%typemap(out) sentencepiece::util::Status {
  if (!$1.ok()) {
    SWIG_exception(ToSwigError($1.code()), $1.ToString().c_str());
  }
  $result = SWIG_From_bool($1.ok());
}

%typemap(in) const std::string & {
  const PyInputString ustring($input);
  if (!ustring.IsAvalable()) {
    PyErr_SetString(PyExc_TypeError, "not a string");
    return nullptr;
  }
  resultobj = ustring.input_type();
  $1 = new std::string(ustring.str(), ustring.size());
}

%typemap(in) const std::vector<std::string>& {
  std::vector<std::string> *out = nullptr;
  if (PyList_Check($input)) {
    const size_t size = PyList_Size($input);
    out = new std::vector<std::string>(size);
    for (size_t i = 0; i < size; ++i) {
      const PyInputString ustring(PyList_GetItem($input, i));
      if (ustring.IsAvalable()) {
        (*out)[i] = std::string(ustring.str(), ustring.size());
      } else {
        PyErr_SetString(PyExc_TypeError, "list must contain strings");
        return nullptr;
      }
      resultobj = ustring.input_type();
    }
  } else {
    PyErr_SetString(PyExc_TypeError, "not a list");
    return nullptr;
  }
  $1 = out;
}

%typemap(in) const std::vector<int>& {
  std::vector<int> *out = nullptr;
  if (PyList_Check($input)) {
    const size_t size = PyList_Size($input);
    out = new std::vector<int>(size);
    for (size_t i = 0; i < size; ++i) {
      PyObject *o = PyList_GetItem($input, i);
      if (PyInt_Check(o)) {
        (*out)[i] = static_cast<int>(PyInt_AsLong(o));
      } else {
        PyErr_SetString(PyExc_TypeError,"list must contain integers");
        return nullptr;
      }
    }
  } else {
    PyErr_SetString(PyExc_TypeError,"not a list");
    return nullptr;
  }
  $1 = out;
}

%typemap(freearg) const std::string& {
  delete $1;
}

%typemap(freearg) const std::vector<std::string>& {
  delete $1;
}

%typemap(freearg) const std::vector<std::vector<std::string>>& {
  delete $1;
}

%typemap(freearg) const std::vector<int>& {
  delete $1;
}

%typemap(freearg) const std::vector<std::vector<int>>& {
  delete $1;
}

%include <sentencepiece_processor.h>
%include <sentencepiece_trainer.h>
