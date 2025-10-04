const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib_mbedtls = b.addLibrary(.{ .name = "mbedtls", .linkage = .static, .root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    }) });

    const lib_mbedcrypto = b.addLibrary(.{ .name = "mbedcrypto", .linkage = .static, .root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    }) });

    const lib_mbedx509 = b.addLibrary(.{ .name = "mbedx509", .linkage = .static, .root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    }) });

    const lib_mbedtls_source_files = [_][]const u8{
        "vendor/library/debug.c",
        "vendor/library/mps_reader.c",
        "vendor/library/mps_trace.c",
        "vendor/library/net_sockets.c",
        "vendor/library/ssl_cache.c",
        "vendor/library/ssl_ciphersuites.c",
        "vendor/library/ssl_client.c",
        "vendor/library/ssl_cookie.c",
        "vendor/library/ssl_debug_helpers_generated.c",
        "vendor/library/ssl_msg.c",
        "vendor/library/ssl_ticket.c",
        "vendor/library/ssl_tls.c",
        "vendor/library/ssl_tls12_client.c",
        "vendor/library/ssl_tls12_server.c",
        "vendor/library/ssl_tls13_keys.c",
        "vendor/library/ssl_tls13_client.c",
        "vendor/library/ssl_tls13_server.c",
        "vendor/library/ssl_tls13_generic.c",
    };

    const lib_mbedx509_source_files = [_][]const u8{
        "vendor/library/x509.c",
        "vendor/library/x509_create.c",
        "vendor/library/x509_crl.c",
        "vendor/library/x509_crt.c",
        "vendor/library/x509_csr.c",
        "vendor/library/x509write.c",
        "vendor/library/x509write_crt.c",
        "vendor/library/x509write_csr.c",
        "vendor/library/pkcs7.c",
    };

    const lib_mbedcrypto_source_files = [_][]const u8{
        "vendor/library/aes.c",
        "vendor/library/aesni.c",
        "vendor/library/aesce.c",
        "vendor/library/aria.c",
        "vendor/library/asn1parse.c",
        "vendor/library/asn1write.c",
        "vendor/library/base64.c",
        "vendor/library/bignum.c",
        "vendor/library/bignum_core.c",
        "vendor/library/bignum_mod.c",
        "vendor/library/bignum_mod_raw.c",
        "vendor/library/block_cipher.c",
        "vendor/library/camellia.c",
        "vendor/library/ccm.c",
        "vendor/library/chacha20.c",
        "vendor/library/chachapoly.c",
        "vendor/library/cipher.c",
        "vendor/library/cipher_wrap.c",
        "vendor/library/cmac.c",
        "vendor/library/constant_time.c",
        "vendor/library/ctr_drbg.c",
        "vendor/library/des.c",
        "vendor/library/dhm.c",
        "vendor/library/ecdh.c",
        "vendor/library/ecdsa.c",
        "vendor/library/ecjpake.c",
        "vendor/library/ecp.c",
        "vendor/library/ecp_curves.c",
        "vendor/library/ecp_curves_new.c",
        "vendor/library/entropy.c",
        "vendor/library/entropy_poll.c",
        "vendor/library/error.c",
        "vendor/library/gcm.c",
        "vendor/library/hkdf.c",
        "vendor/library/hmac_drbg.c",
        "vendor/library/lmots.c",
        "vendor/library/lms.c",
        "vendor/library/md.c",
        "vendor/library/md5.c",
        "vendor/library/memory_buffer_alloc.c",
        "vendor/library/nist_kw.c",
        "vendor/library/oid.c",
        "vendor/library/padlock.c",
        "vendor/library/pem.c",
        "vendor/library/pk.c",
        "vendor/library/pk_ecc.c",
        "vendor/library/pk_wrap.c",
        "vendor/library/pkcs12.c",
        "vendor/library/pkcs5.c",
        "vendor/library/pkparse.c",
        "vendor/library/pkwrite.c",
        "vendor/library/platform.c",
        "vendor/library/platform_util.c",
        "vendor/library/poly1305.c",
        "vendor/library/psa_crypto.c",
        "vendor/library/psa_crypto_aead.c",
        "vendor/library/psa_crypto_cipher.c",
        "vendor/library/psa_crypto_client.c",
        "vendor/library/psa_crypto_driver_wrappers_no_static.c",
        "vendor/library/psa_crypto_ecp.c",
        "vendor/library/psa_crypto_ffdh.c",
        "vendor/library/psa_crypto_hash.c",
        "vendor/library/psa_crypto_mac.c",
        "vendor/library/psa_crypto_pake.c",
        "vendor/library/psa_crypto_rsa.c",
        "vendor/library/psa_crypto_se.c",
        "vendor/library/psa_crypto_slot_management.c",
        "vendor/library/psa_crypto_storage.c",
        "vendor/library/psa_its_file.c",
        "vendor/library/psa_util.c",
        "vendor/library/ripemd160.c",
        "vendor/library/rsa.c",
        "vendor/library/rsa_alt_helpers.c",
        "vendor/library/sha1.c",
        "vendor/library/sha256.c",
        "vendor/library/sha512.c",
        "vendor/library/sha3.c",
        "vendor/library/threading.c",
        "vendor/library/timing.c",
        "vendor/library/version.c",
        "vendor/library/version_features.c",
    };

    lib_mbedtls.addCSourceFiles(.{ .files = &lib_mbedtls_source_files });
    lib_mbedtls.addIncludePath(b.path("vendor/include"));
    lib_mbedcrypto.addCSourceFiles(.{ .files = &lib_mbedcrypto_source_files });
    lib_mbedcrypto.addIncludePath(b.path("vendor/include"));
    lib_mbedx509.addCSourceFiles(.{ .files = &lib_mbedx509_source_files });
    lib_mbedx509.addIncludePath(b.path("vendor/include"));

    lib_mbedx509.linkLibrary(lib_mbedcrypto);
    lib_mbedtls.linkLibrary(lib_mbedx509);
    lib_mbedtls.linkLibrary(lib_mbedcrypto);

    b.installArtifact(lib_mbedtls);
    b.installArtifact(lib_mbedcrypto);
    b.installArtifact(lib_mbedx509);
}
