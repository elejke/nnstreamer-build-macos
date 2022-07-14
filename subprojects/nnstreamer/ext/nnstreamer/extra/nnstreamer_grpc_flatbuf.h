/* SPDX-License-Identifier: LGPL-2.1-only */
/**
 * GStreamer / NNStreamer gRPC/flatbuf support
 * Copyright (C) 2020 Dongju Chae <dongju.chae@samsung.com>
 */
/**
 * @file    nnstreamer_grpc_flatbuffer.h
 * @date    26 Nov 2020
 * @brief   nnstreamer gRPC/Flatbuf support
 * @see     https://github.com/nnstreamer/nnstreamer
 * @author  Dongju Chae <dongju.chae@samsung.com>
 * @bug     No known bugs except for NYI items
 */

#ifndef __NNS_GRPC_FLATBUF_H__
#define __NNS_GRPC_FLATBUF_H__

#include "nnstreamer_grpc_common.h"
#include "nnstreamer.grpc.fb.h" /* Generated by `flatc` */

using nnstreamer::flatbuf::TensorService;
using nnstreamer::flatbuf::Tensors;
using nnstreamer::flatbuf::Tensor;
using nnstreamer::flatbuf::Empty;

using flatbuffers::grpc::Message;

namespace grpc {

/**
 * @brief NNStreamer gRPC flatbuf service impl.
 */
class ServiceImplFlatbuf : public NNStreamerRPC
{
  public:
    ServiceImplFlatbuf (const grpc_config * config);

    void parse_tensors (Message<Tensors> &tensors);
    gboolean fill_tensors (Message<Tensors> &tensors);

  protected:
    template <typename T>
    grpc::Status _write_tensors (T writer);

    template <typename T>
    grpc::Status _read_tensors (T reader);

    void _get_tensors_from_buffer (GstBuffer *buffer, Message<Tensors> &tensors);
    void _get_buffer_from_tensors (Message<Tensors> &tensors, GstBuffer **buffer);

    std::unique_ptr<nnstreamer::flatbuf::TensorService::Stub> client_stub_;
};

/**
 * @brief NNStreamer gRPC flatbuf sync service impl.
 */
class SyncServiceImplFlatbuf final
  : public ServiceImplFlatbuf, public TensorService::Service
{
  public:
    SyncServiceImplFlatbuf (const grpc_config * config);

    Status SendTensors (ServerContext *context, ServerReader<Message<Tensors>> *reader,
        Message<Empty> *replay) override;

    Status RecvTensors (ServerContext *context, const Message<Empty> *request,
        ServerWriter<Message<Tensors>> *writer) override;

  private:
    gboolean start_server (std::string address) override;
    gboolean start_client (std::string address) override;

    void _client_thread ();
};

class AsyncCallData;

/**
 * @brief NNStreamer gRPC flatbuf async service impl.
 */
class AsyncServiceImplFlatbuf final
  : public ServiceImplFlatbuf, public TensorService::AsyncService
{
  public:
    AsyncServiceImplFlatbuf (const grpc_config * config);
    ~AsyncServiceImplFlatbuf ();

    /** @brief set the last call data */
    void set_last_call (AsyncCallData * call) { last_call_ = call; }

  private:
    gboolean start_server (std::string address) override;
    gboolean start_client (std::string address) override;

    void _server_thread ();
    void _client_thread ();

    AsyncCallData * last_call_;
};

/** @brief Internal base class to serve a request */
class AsyncCallData {
  public:
    /** @brief Constructor of AsyncCallData */
    AsyncCallData (AsyncServiceImplFlatbuf *service)
      : service_ (service), state_ (CREATE), count_ (0)
    {
    }

    /** @brief Destructor of AsyncCallData */
    virtual ~AsyncCallData () {}

    /** @brief FSM-based state handling function */
    virtual void RunState (bool ok) {}

  protected:
    enum CallState { CREATE, PROCESS, FINISH, DESTROY };

    AsyncServiceImplFlatbuf *service_;
    CallState state_;
    guint count_;

    Message<Tensors> rpc_tensors_;
    Message<Empty> rpc_empty_;
};

}; // namespace grpc

#endif /* __NNS_GRPC_FLATBUF_H__ */