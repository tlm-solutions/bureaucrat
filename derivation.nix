{ craneLib, src, lib, cmake, pkg-config, protobuf, grpc, openssl, postgresql}:

craneLib.buildPackage {
  pname = "bureaucrat";
  version = "0.1.0";

  src = ./.;

  buildInputs = [ cmake protobuf grpc openssl pkg-config postgresql ];

  meta = {
    description = "Service which feeds a redis instance with geo data";
    homepage = "https://github.com/tlm-solutions/bureaucrat";
  };
}
