//
//  AppServiceLocator.cpp
//  MyMonero
//
//  Copyright (c) 2014-2019, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//

#include "AppServiceLocator.hpp"
using namespace App;
//
//
// Not needed
//class App::ServiceLocator_SpecificImpl
//{
//public:
////	io_context io_ctx;
////	io_ctx_thread_holder ctx_thread_holder{io_ctx};
//	//
//	ServiceLocator_SpecificImpl() {}
//	~ServiceLocator_SpecificImpl() {}
//};
//
ServiceLocator::~ServiceLocator()
{
	if (_pImpl != NULL) {
		delete _pImpl; // must free .... and here, since we can only free in the place where the type is completely defined
		_pImpl = NULL;
	}
	teardown();
}
//
//ServiceLocator &ServiceLocator::build(
//	std::shared_ptr<string> documentsPath,
//	network_type nettype,
//	std::shared_ptr<Passwords::PasswordEntryDelegate> initial_passwordEntryDelegate_ptr
//) {
//	ServiceLocator_SpecificImpl *pImpl_ptr = new ServiceLocator_SpecificImpl();
//	//
//	return shared_build(
//		pImpl_ptr,
//		documentsPath,
//		nettype,
//		std::make_shared<HTTPRequests::RequestFactory_beast>(pImpl_ptr->io_ctx),
//		std::make_shared<Dispatch_asio>(pImpl_ptr->ctx_thread_holder),
//		initial_passwordEntryDelegate_ptr
//	);
//}


